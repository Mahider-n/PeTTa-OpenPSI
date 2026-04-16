
import argparse
import json
import os
import queue
import re
import socket
import threading
import tkinter as tk
from typing import Any

import dearpygui.dearpygui as dpg

# OpenClaw-specific demands 
FIXED_DEMANDS = ["Responsiveness", "Helpfulness", "Curiosity", "Energy"]
METRIC_BAR_WIDTH = 280


def clamp_progress(value: float) -> float:
    return max(0.0, min(1.0, float(value)))


def normalize_progress(value: float) -> float:
    if value > 1.0:
        value = value / 100.0
    return clamp_progress(value)


def to_float(value: Any) -> "float | None":
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value.strip())
        except ValueError:
            return None
    return None


def to_text(value: Any) -> str:
    return value if isinstance(value, str) else str(value)


def parse_pairs(values: list) -> "dict[str, float]":
    parsed: dict[str, float] = {}
    if len(values) % 2 != 0:
        return parsed
    for i in range(0, len(values), 2):
        v = to_float(values[i + 1])
        if v is not None:
            parsed[to_text(values[i])] = normalize_progress(v)
    return parsed


def parse_demand_entry(entry: Any) -> "tuple[str, float] | None":
    # [demand, name, min, max, value]
    if isinstance(entry, (list, tuple)) and len(entry) >= 5:
        kind = to_text(entry[0]).strip().lower()
        name = to_text(entry[1]).strip()
        value = to_float(entry[4])
        if kind == "demand" and name and value is not None:
            return name, normalize_progress(value)
    # "demand name min max value"
    if isinstance(entry, str):
        m = re.match(
            r"^\(?\s*demand\s+(\S+)\s+\S+\s+\S+\s+([-+]?\d*\.?\d+)\s*\)?$",
            entry.strip(), re.IGNORECASE,
        )
        if m:
            return m.group(1), normalize_progress(float(m.group(2)))
    return None


def parse_demand_payload(event_data: Any) -> "dict[str, float]":
    demands: dict[str, float] = {}
    if isinstance(event_data, (list, tuple)):
        pair_demands = parse_pairs(event_data)
        if pair_demands:
            return pair_demands
        single = parse_demand_entry(event_data)
        if single:
            demands[single[0]] = single[1]
            return demands
        for entry in event_data:
            parsed = parse_demand_entry(entry)
            if parsed:
                demands[parsed[0]] = parsed[1]
        return demands
    if isinstance(event_data, str):
        single = parse_demand_entry(event_data)
        if single:
            demands[single[0]] = single[1]
    return demands


def parse_typed_event(payload: Any) -> "dict[str, Any] | None":
    if not isinstance(payload, list) or len(payload) < 2:
        return None
    event_type = to_text(payload[0]).strip().lower()
    event_data = payload[1]
    if event_type == "demand":
        return {"label": "Demand update", "demands": parse_demand_payload(event_data)}
    if event_type == "action":
        action_text = (
            " ".join(str(i) for i in event_data)
            if isinstance(event_data, (list, tuple))
            else to_text(event_data).strip()
        )
        return {"label": "Action update", "action": action_text}
    return {"label": str(payload)}


def parse_update(line: str) -> "dict[str, Any] | None":
    line = line.strip()
    if not line:
        return None
    try:
        payload = json.loads(line)
    except json.JSONDecodeError:
        payload = line
    typed = parse_typed_event(payload)
    if typed:
        return typed
    if isinstance(payload, str):
        try:
            return {"progress": normalize_progress(float(payload)),
                    "label": f"{int(normalize_progress(float(payload)) * 100)}%"}
        except ValueError:
            return {"label": payload}
    return {"label": str(payload)}


def slugify(name: str) -> str:
    return re.sub(r"[^0-9A-Za-z_]+", "_", name).strip("_") or "item"


def normalize_demand_name(name: str) -> "str | None":
    """Match incoming demand names (any case) to our FIXED_DEMANDS list."""
    cleaned = re.sub(r"[^a-z0-9]+", "", name.strip().lower())
    for demand in FIXED_DEMANDS:
        candidate = re.sub(r"[^a-z0-9]+", "", demand.lower())
        if cleaned == candidate:
            return demand
    return None


def update_metric_section(
    parent_tag: str,
    section_prefix: str,
    values: "dict[str, float]",
    row_tags: "dict[str, tuple[str, str, str]]",
    bar_width: int = METRIC_BAR_WIDTH,
) -> None:
    stale = [k for k in row_tags if k not in values]
    for k in stale:
        dpg.delete_item(row_tags[k][0])
        del row_tags[k]

    for name, value in values.items():
        clamped = clamp_progress(value)
        if name not in row_tags:
            safe = slugify(name)
            row_tag   = f"{section_prefix}_row_{safe}"
            bar_tag   = f"{section_prefix}_bar_{safe}"
            label_tag = f"{section_prefix}_label_{safe}"
            suffix = 2
            while dpg.does_item_exist(row_tag):
                row_tag   = f"{section_prefix}_row_{safe}_{suffix}"
                bar_tag   = f"{section_prefix}_bar_{safe}_{suffix}"
                label_tag = f"{section_prefix}_label_{safe}_{suffix}"
                suffix += 1
            with dpg.table_row(parent=parent_tag, tag=row_tag):
                dpg.add_text(default_value=name, tag=label_tag)
                dpg.add_progress_bar(
                    default_value=clamped,
                    width=bar_width,
                    overlay=f"{int(clamped * 100)}%",
                    tag=bar_tag,
                )
            row_tags[name] = (row_tag, label_tag, bar_tag)
        else:
            _, label_tag, bar_tag = row_tags[name]
            dpg.set_value(bar_tag, clamped)
            dpg.configure_item(bar_tag, overlay=f"{int(clamped * 100)}%")


def tcp_listener(
    host: str, port: int,
    updates: queue.Queue,
    stop_event: threading.Event,
) -> None:
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((host, port))
    server.listen()
    server.settimeout(1.0)
    updates.put({"label": f"Listening on {host}:{port}"})
    try:
        while not stop_event.is_set():
            try:
                conn, addr = server.accept()
            except socket.timeout:
                continue
            updates.put({"label": f"Connected: {addr[0]}:{addr[1]}"})
            conn.settimeout(1.0)
            buf = ""
            with conn:
                while not stop_event.is_set():
                    try:
                        chunk = conn.recv(1024)
                    except socket.timeout:
                        continue
                    if not chunk:
                        updates.put({"label": "Listening for updates"})
                        break
                    buf += chunk.decode("utf-8", errors="replace")
                    while "\n" in buf:
                        line, buf = buf.split("\n", 1)
                        upd = parse_update(line)
                        if upd:
                            updates.put(upd)
    finally:
        server.close()


def get_screen_size() -> "tuple[int, int]":
    try:
        root = tk.Tk()
        root.withdraw()
        w, h = root.winfo_screenwidth(), root.winfo_screenheight()
        root.destroy()
        return w, h
    except Exception:
        return 1280, 720


def run_dashboard(host: str, port: int) -> None:
    updates: queue.Queue = queue.Queue()
    stop_event = threading.Event()
    threading.Thread(
        target=tcp_listener, args=(host, port, updates, stop_event), daemon=True
    ).start()

    vw, vh = 480, 340
    sw, sh = get_screen_size()
    margin = 20

    dpg.create_context()
    with dpg.window(tag="main_window", label="OpenPsi — OpenClaw Agent",
                    no_resize=True, no_move=True, no_collapse=True):
        dpg.add_text(default_value="Starting...", tag="status_text")
        dpg.add_separator()
        dpg.add_text("Demands")
        with dpg.table(
            tag="demands_container", header_row=False,
            policy=dpg.mvTable_SizingFixedFit,
            borders_innerH=False, borders_outerH=False,
            borders_innerV=False, borders_outerV=False,
        ):
            dpg.add_table_column(init_width_or_weight=120, width_fixed=True)
            dpg.add_table_column(init_width_or_weight=METRIC_BAR_WIDTH, width_fixed=True)
        dpg.add_separator()
        dpg.add_text(default_value="Action: (none)", tag="action_text")

    dpg.create_viewport(
        title="OpenPsi Stats",
        width=vw, height=vh,
        x_pos=max(0, sw - vw - margin),
        y_pos=max(0, sh - vh - margin),
        always_on_top=True,
    )
    dpg.setup_dearpygui()
    dpg.show_viewport()
    dpg.set_primary_window("main_window", True)

    demand_row_tags: "dict[str, tuple[str, str, str]]" = {}
    # Initialise with equal values for our 4 demands
    demand_state: "dict[str, float]" = {d: 1.0 / len(FIXED_DEMANDS) for d in FIXED_DEMANDS}
    update_metric_section("demands_container", "demand", demand_state, demand_row_tags)

    try:
        while dpg.is_dearpygui_running():
            while not updates.empty():
                upd = updates.get_nowait()

                if "demands" in upd and isinstance(upd["demands"], dict):
                    for raw_name, value in upd["demands"].items():
                        norm = normalize_demand_name(str(raw_name))
                        if norm:
                            demand_state[norm] = clamp_progress(float(value))
                    update_metric_section(
                        "demands_container", "demand", demand_state, demand_row_tags
                    )

                if "action" in upd:
                    dpg.set_value("action_text", f"Action: {upd['action']}")

                if "label" in upd:
                    dpg.set_value("status_text", str(upd["label"]))

            dpg.render_dearpygui_frame()
    finally:
        stop_event.set()
        dpg.destroy_context()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default=os.getenv("OPENPSI_DASHBOARD_HOST", "127.0.0.1"))
    parser.add_argument("--port", type=int, default=int(os.getenv("OPENPSI_DASHBOARD_PORT", "5001")))
    args = parser.parse_args()
    run_dashboard(args.host, args.port)


if __name__ == "__main__":
    main()
