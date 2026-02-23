from benchmark_helper import run_and_get_result
import matplotlib.pyplot as plt

def plot_money_over_time(command_args,title, save_path="nars_plot.png"):
    """Builds on the extractor to generate a Matplotlib visualization."""
    
    
    data = run_and_get_result(command_args)
    
    if not data:
        print("No data available to plot.")
        return

    
    plt.figure(figsize=(10, 6))
    iterations = range(len(data))
    

    plt.plot(iterations, data, color='#2ca02c', marker='o', linewidth=2, label='Total Balance')
    

    plt.title(title, fontsize=14, fontweight='bold')
    plt.xlabel('Number of Iterations', fontsize=12)
    plt.ylabel('Total Money', fontsize=12)
    
    if min(data) < 0:
        plt.axhline(0, color='black', linewidth=0.8, linestyle='--')
        
    plt.grid(True, which='both', linestyle=':', alpha=0.6)
    plt.legend()

    
    plt.tight_layout()
    plt.savefig(save_path)
    plt.show()
    print(f"Success! Plot saved to {save_path}")

if __name__ == "__main__":
    plot_money_over_time(["petta", "main.metta"],"PLN based planner payoffs")