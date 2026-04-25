from __future__ import annotations

import argparse
import json
import os
import re
import tempfile
from collections import Counter
from pathlib import Path

os.environ.setdefault(
    "MPLCONFIGDIR",
    str(Path(tempfile.gettempdir()) / "openclaw-matplotlib-cache"),
)

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


RULE_NAMES = {
    1: "Urgent response",
    2: "Search + respond",
    3: "Simple response",
    4: "Wait",
    5: "Explore",
}


def parse_perception(line: str) -> dict:
    perception = {}
    for key, raw_value in re.findall(r"\((\w+)\s+(\".*?\"|[^()]+)\)", line):
        value = raw_value.strip()
        if value.startswith('"') and value.endswith('"'):
            value = value[1:-1]
        elif value.lower() in {"true", "false"}:
            value = value.lower() == "true"
        elif re.fullmatch(r"-?\d+", value):
            value = int(value)
        else:
            try:
                value = float(value)
            except ValueError:
                pass
        perception[key] = value
    return perception


def parse_demand(line: str) -> dict | None:
    match = re.search(r"\(demand\s+(\w+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\)", line)
    if not match:
        return None
    return {
        "name": match.group(1),
        "min": float(match.group(2)),
        "max": float(match.group(3)),
        "value": float(match.group(4)),
    }


class SimpleOpenPsiAnalyzer:
    def __init__(self, log_file: str):
        self.log_file = Path(log_file)
        self.steps: list[dict] = []

    def parse(self) -> None:
        lines = self.log_file.read_text(encoding="utf-8", errors="ignore").splitlines()

        start_index = None
        for index, line in enumerate(lines):
            if re.search(r"\(Step 1 / \d+\)", line):
                start_index = index
                break

        if start_index is None:
            raise ValueError("Could not find '(Step 1 / N)' in the log file.")

        current_step = None

        for line_number, raw_line in enumerate(lines[start_index:], start=start_index + 1):
            line = raw_line.strip()

            step_match = re.search(r"\(Step (\d+) / (\d+)\)", line)
            if step_match:
                if current_step:
                    self.steps.append(current_step)
                current_step = {
                    "index": len(self.steps) + 1,
                    "step_num": int(step_match.group(1)),
                    "step_total": int(step_match.group(2)),
                    "line_number": line_number,
                    "perception": {},
                    "selected_demand": None,
                    "selected_goal": None,
                    "chosen_rule": None,
                    "rule_score": None,
                    "actions": [],
                    "search_no_query": False,
                    "response_sent": False,
                    "rule_update": None,
                }
                continue

            if current_step is None:
                continue

            if "perception:" in line and "hasMessage" in line:
                current_step["perception"] = parse_perception(line)
                continue

            if "Selected-Demand:" in line:
                current_step["selected_demand"] = parse_demand(line)
                continue

            goal_match = re.search(r"\(Selected-Goal:\s*([^)]+)\)", line)
            if goal_match:
                current_step["selected_goal"] = goal_match.group(1).strip()
                continue

            rule_match = re.search(r"\(Chosen-Rule:\s*(\d+)\s+Score:\s*([\d.]+)\)", line)
            if rule_match:
                current_step["chosen_rule"] = int(rule_match.group(1))
                current_step["rule_score"] = float(rule_match.group(2))
                continue

            action_match = re.search(r"\(Action:\s+\(([^)]+)\)\s+->\s+(.+)\)", line)
            if action_match:
                action_name = action_match.group(1).strip()
                action_result = action_match.group(2).strip()
                current_step["actions"].append(
                    {"name": action_name, "result": action_result}
                )
                if "No query provided for web search" in action_result:
                    current_step["search_no_query"] = True
                continue

            if "OPENPSI IS REPLYING VIA CLI" in line:
                current_step["response_sent"] = True
                continue

            update_match = re.search(
                r'New STV: \(\s*"([\d.]+)\s*",\s*"([\d.]+)\s*"\)',
                line,
            )
            if update_match:
                current_step["rule_update"] = {
                    "strength": float(update_match.group(1)),
                    "confidence": float(update_match.group(2)),
                }

        if current_step:
            self.steps.append(current_step)

    def analyze(self) -> dict:
        if not self.steps:
            return {}

        rule_counts = Counter(
            step["chosen_rule"] for step in self.steps if step["chosen_rule"] is not None
        )
        goal_counts = Counter(
            step["selected_goal"] for step in self.steps if step["selected_goal"]
        )
        action_counts = Counter(
            action["name"] for step in self.steps for action in step["actions"]
        )

        message_steps = [step for step in self.steps if step["perception"].get("hasMessage")]
        info_request_steps = [
            step for step in self.steps if step["perception"].get("infoRequest")
        ]
        no_message_steps = [
            step for step in self.steps if step["perception"].get("noMessage")
        ]
        search_no_query_steps = [step for step in self.steps if step["search_no_query"]]

        rules_on_messages = Counter(
            step["chosen_rule"]
            for step in message_steps
            if step["chosen_rule"] is not None
        )

        message_samples = []
        for step in message_steps:
            message_text = step["perception"].get("messageText", "")
            message_samples.append(
                {
                    "step_index": step["index"],
                    "message": message_text,
                    "rule": step["chosen_rule"],
                    "goal": step["selected_goal"],
                    "info_request": step["perception"].get("infoRequest", False),
                }
            )

        return {
            "log_file": str(self.log_file),
            "total_steps": len(self.steps),
            "message_steps": len(message_steps),
            "no_message_steps": len(no_message_steps),
            "info_request_steps": len(info_request_steps),
            "responses_sent": sum(1 for step in self.steps if step["response_sent"]),
            "search_no_query_steps": len(search_no_query_steps),
            "rule_counts": dict(sorted(rule_counts.items())),
            "goal_counts": dict(sorted(goal_counts.items())),
            "action_counts": dict(sorted(action_counts.items())),
            "rules_on_message_steps": dict(sorted(rules_on_messages.items())),
            "message_samples": message_samples[:10],
        }

    def build_report(self) -> str:
        analysis = self.analyze()
        if not analysis:
            return "No steps were parsed."

        lines = []
        lines.append("=" * 80)
        lines.append("OPENPSI STEP ANALYSIS")
        lines.append("=" * 80)
        lines.append(f"Log file: {analysis['log_file']}")
        lines.append(f"Parsed steps: {analysis['total_steps']}")
        lines.append(f"Steps with messages: {analysis['message_steps']}")
        lines.append(f"Steps with no messages: {analysis['no_message_steps']}")
        lines.append(f"Info-request steps: {analysis['info_request_steps']}")
        lines.append(f"Responses sent: {analysis['responses_sent']}")
        lines.append(
            f"Steps where search ran without a query: {analysis['search_no_query_steps']}"
        )

        lines.append("\nRULE COUNTS")
        lines.append("-" * 40)
        for rule_id, count in analysis["rule_counts"].items():
            label = RULE_NAMES.get(int(rule_id), f"Rule {rule_id}")
            lines.append(f"Rule {rule_id} ({label}): {count}")

        lines.append("\nGOAL COUNTS")
        lines.append("-" * 40)
        for goal, count in analysis["goal_counts"].items():
            lines.append(f"{goal}: {count}")

        lines.append("\nACTION COUNTS")
        lines.append("-" * 40)
        for action, count in analysis["action_counts"].items():
            lines.append(f"{action}: {count}")

        lines.append("\nRULES CHOSEN WHEN A MESSAGE WAS PRESENT")
        lines.append("-" * 40)
        if analysis["rules_on_message_steps"]:
            for rule_id, count in analysis["rules_on_message_steps"].items():
                label = RULE_NAMES.get(int(rule_id), f"Rule {rule_id}")
                lines.append(f"Rule {rule_id} ({label}): {count}")
        else:
            lines.append("No message-handling steps were found.")

        lines.append("\nMESSAGE SAMPLES")
        lines.append("-" * 40)
        if analysis["message_samples"]:
            for sample in analysis["message_samples"]:
                rule = sample["rule"]
                label = RULE_NAMES.get(rule, f"Rule {rule}") if rule else "No rule"
                lines.append(
                    f"Step {sample['step_index']}: '{sample['message']}' | "
                    f"goal={sample['goal']} | rule={label} | "
                    f"infoRequest={sample['info_request']}"
                )
        else:
            lines.append("No message samples found.")

        lines.append("\nMAIN TAKEAWAYS")
        lines.append("-" * 40)

        top_rule_id = None
        top_rule_count = 0
        if analysis["rule_counts"]:
            top_rule_id, top_rule_count = max(
                analysis["rule_counts"].items(), key=lambda item: item[1]
            )
            label = RULE_NAMES.get(int(top_rule_id), f"Rule {top_rule_id}")
            lines.append(f"Most chosen rule: Rule {top_rule_id} ({label}) = {top_rule_count}")

        if analysis["search_no_query_steps"]:
            lines.append(
                "Search is being triggered without a query in some steps, so those searches cannot succeed."
            )

        if analysis["message_steps"] and analysis["rules_on_message_steps"]:
            dominant_message_rule, dominant_message_count = max(
                analysis["rules_on_message_steps"].items(), key=lambda item: item[1]
            )
            label = RULE_NAMES.get(int(dominant_message_rule), f"Rule {dominant_message_rule}")
            lines.append(
                f"When messages exist, the most common handler is Rule {dominant_message_rule} ({label}) = {dominant_message_count}"
            )

        return "\n".join(lines)

    def save_visualizations(self, output_dir: Path) -> None:
        output_dir.mkdir(parents=True, exist_ok=True)

        step_indices = [step["index"] for step in self.steps if step["chosen_rule"] is not None]
        chosen_rules = [step["chosen_rule"] for step in self.steps if step["chosen_rule"] is not None]
        message_rule_steps = [
            step for step in self.steps if step["chosen_rule"] is not None and step["perception"].get("hasMessage")
        ]

        if step_indices:
            plt.figure(figsize=(12, 5))
            plt.plot(step_indices, chosen_rules, color="#2a6f97", linewidth=2, marker="o", markersize=4)

            if message_rule_steps:
                plt.scatter(
                    [step["index"] for step in message_rule_steps],
                    [step["chosen_rule"] for step in message_rule_steps],
                    color="#d62828",
                    s=40,
                    label="Message present",
                    zorder=3,
                )
                plt.legend()

            plt.yticks(sorted(set(chosen_rules)))
            plt.xlabel("Parsed step sequence")
            plt.ylabel("Chosen rule")
            plt.title("Rule Choice Timeline")
            plt.grid(True, axis="y", alpha=0.25)
            plt.tight_layout()
            plt.savefig(output_dir / "rule_choice_timeline.png", dpi=160, bbox_inches="tight")
            plt.close()

        rule_counts = Counter(
            step["chosen_rule"] for step in self.steps if step["chosen_rule"] is not None
        )
        action_counts = Counter(
            action["name"] for step in self.steps for action in step["actions"]
        )

        fig, axes = plt.subplots(1, 2, figsize=(14, 5))

        if rule_counts:
            rule_labels = [f"Rule {rule_id}" for rule_id in rule_counts.keys()]
            axes[0].bar(rule_labels, list(rule_counts.values()), color="#457b9d")
            axes[0].set_title("Rule Counts")
            axes[0].set_ylabel("Count")
        else:
            axes[0].text(0.5, 0.5, "No rule data", ha="center", va="center")
            axes[0].set_axis_off()

        if action_counts:
            axes[1].bar(action_counts.keys(), action_counts.values(), color="#8d99ae")
            axes[1].set_title("Action Counts")
            axes[1].set_ylabel("Count")
            axes[1].tick_params(axis="x", rotation=20)
        else:
            axes[1].text(0.5, 0.5, "No action data", ha="center", va="center")
            axes[1].set_axis_off()

        plt.tight_layout()
        plt.savefig(output_dir / "rule_and_action_summary.png", dpi=160, bbox_inches="tight")
        plt.close()


def main() -> None:
    parser = argparse.ArgumentParser(description="Analyze an OpenPsi terminal log.")
    parser.add_argument("log_file", help="Path to the tee output text file")
    parser.add_argument(
        "--output-dir",
        default=None,
        help="Directory for generated PNGs and report. Defaults beside the log file.",
    )
    parser.add_argument(
        "--export-json",
        action="store_true",
        help="Also write a compact JSON summary.",
    )
    args = parser.parse_args()

    analyzer = SimpleOpenPsiAnalyzer(args.log_file)

    print(f"Analyzing log file: {args.log_file}")
    print("This may take a moment...\n")

    analyzer.parse()

    default_output_dir = analyzer.log_file.parent / "analysis_output"
    output_dir = Path(args.output_dir) if args.output_dir else default_output_dir
    report_path = output_dir / "analysis_report.txt"
    json_path = output_dir / "analysis.json"

    report = analyzer.build_report()

    output_dir.mkdir(parents=True, exist_ok=True)
    report_path.write_text(report, encoding="utf-8")
    print("Analysis complete.")
    print(f"\n✅ Report saved to '{report_path.resolve()}'")

    analyzer.save_visualizations(output_dir)
    print(f"✅ Visualizations saved to '{output_dir.resolve()}/'")

    if args.export_json:
        json_path.write_text(
            json.dumps(analyzer.analyze(), indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
        print(f"✅ JSON saved to '{json_path.resolve()}'")


if __name__ == "__main__":
    main()
