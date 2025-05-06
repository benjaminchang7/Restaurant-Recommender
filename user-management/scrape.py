import os

def scrape_directory(base_dir, output_file):
    with open(output_file, 'w', encoding='utf-8') as out_f:
        for root, dirs, files in os.walk(base_dir):
            for file in files:
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                except Exception as e:
                    content = f"<Could not read file: {e}>"

                out_f.write(f"=== FILE: {file_path} ===\n")
                out_f.write(content + "\n\n")
                print(f"Processed: {file_path}")

if __name__ == "__main__":
    # Replace '.' with your target directory, and 'output.txt' with desired output file
    scrape_directory('.', 'scraped_output.txt')
