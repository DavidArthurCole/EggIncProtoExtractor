def cleanup():
    MAIN_PROTO_PATH = 'protos/ei.proto'
    COMMON_PROTO_PATH = 'protos/common.proto'
    
    # Read content from common.proto excluding the first 3 lines (syntax, package)
    try:
        with open(COMMON_PROTO_PATH, 'r') as common_file:
            common_lines = common_file.readlines()[3:]  # Skip the first 3 lines (syntax, package)
    except FileNotFoundError:
        print(f"Error: {COMMON_PROTO_PATH} not found.")
        return
    
    # Remove the last newline from common.proto content
    if common_lines:
        common_lines[-1] = common_lines[-1].rstrip()

    # Read content from main proto file
    try:
        with open(MAIN_PROTO_PATH, 'r') as main_file:
            lines = main_file.readlines()
    except FileNotFoundError:
        print(f"Error: {MAIN_PROTO_PATH} not found.")
        return
    
    # Filter out the import line and its surrounding whitespace
    lines = [line for line in lines if not line.strip().startswith('import "common.proto";')]
    
    # Find the index where package ei; is declared
    package_index = next((i for i, line in enumerate(lines) if line.strip().startswith('package ei;')), None)
    
    if package_index is not None and common_lines:
        # Insert content from common.proto after the package declaration
        lines = lines[:package_index + 1] + common_lines + lines[package_index + 1:]
    
    # Replace `aux.` with `` in the main proto file
    lines = [line.replace('aux.', '') for line in lines]

    # Write back to main proto file
    try:
        with open(MAIN_PROTO_PATH, 'w') as main_file:
            main_file.writelines(lines)
        print(f"Successfully cleaned up {MAIN_PROTO_PATH}.")
    except Exception as e:
        print(f"Error: Failed to write to {MAIN_PROTO_PATH}. {e}")

if __name__ == '__main__':
    cleanup()