import subprocess
import re
    
def run_and_get_result(command_args):
    try:
        
        result = subprocess.run(
            command_args,
            capture_output=True,
            text=True,
            check=True
        )
        
        output = result.stdout.strip()

        
        all_matches = re.findall(r'\(\s*(-?\d+(?:\s+-?\d+)*)\s*\)', output)

        if not all_matches:
            print("No S-expressions found in the output.")
            return []

        
        last_sexpr_content = all_matches[-1]
        integer_list = [int(n) for n in last_sexpr_content.split()]
        
        return integer_list

    except subprocess.CalledProcessError as e:
        print(f"Subprocess failed with error: {e.stderr}")
        return []
    except Exception as e:
        print(f"An error occurred: {e}")
        return []

if __name__ == '__main__':
    res = run_and_get_result(["petta", "main.metta"])

    print(res)