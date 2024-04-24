def cleanup():
    MAIN_PROTO_PATH = 'protos/ei.proto'
    COMMON_PROTO_PATH = 'protos/common.proto'
    
    # Read content from common.proto excluding the first 3 lines
    with open(COMMON_PROTO_PATH, 'r') as common_file:
        common_lines = common_file.readlines()[3:]  # Skip the first 3 lines
    
    # Read content from main proto file
    with open(MAIN_PROTO_PATH, 'r') as main_file:
        lines = main_file.readlines()
    
    # Find the index of the import line
    import_line_index = next((i for i, line in enumerate(lines) if line.startswith('import "common.proto";')), None)
    
    if import_line_index is not None:
        # Insert content from common.proto after the import line
        lines = lines[:import_line_index + 1] + common_lines + lines[import_line_index + 1:]
    
    lines = [line.replace('aux.', '') for line in lines]
    with open(MAIN_PROTO_PATH, 'w') as main_file:
        main_file.writelines(lines)

if __name__ == '__main__':
    cleanup()