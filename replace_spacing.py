import os
import re

def replace_spacing(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replace arbitrary spacing
    content = re.sub(r'SizedBox\(\s*height:\s*12\s*\)', 'SizedBox(height: 16)', content)
    content = re.sub(r'SizedBox\(\s*height:\s*10\s*\)', 'SizedBox(height: 8)', content)
    content = re.sub(r'SizedBox\(\s*height:\s*20\s*\)', 'SizedBox(height: 24)', content)
    content = re.sub(r'SizedBox\(\s*height:\s*6\s*\)', 'SizedBox(height: 8)', content)
    content = re.sub(r'SizedBox\(\s*height:\s*4\s*\)', 'SizedBox(height: 8)', content)
    
    content = re.sub(r'SizedBox\(\s*width:\s*12\s*\)', 'SizedBox(width: 16)', content)
    content = re.sub(r'SizedBox\(\s*width:\s*10\s*\)', 'SizedBox(width: 8)', content)
    content = re.sub(r'SizedBox\(\s*width:\s*20\s*\)', 'SizedBox(width: 24)', content)
    content = re.sub(r'SizedBox\(\s*width:\s*6\s*\)', 'SizedBox(width: 8)', content)
    content = re.sub(r'SizedBox\(\s*width:\s*4\s*\)', 'SizedBox(width: 8)', content)

    # Replace EdgeInsets
    content = re.sub(r'EdgeInsets\.all\(\s*12\s*\)', 'EdgeInsets.all(16)', content)
    content = re.sub(r'EdgeInsets\.all\(\s*20\s*\)', 'EdgeInsets.all(24)', content)
    content = re.sub(r'EdgeInsets\.all\(\s*10\s*\)', 'EdgeInsets.all(8)', content)

    content = re.sub(r'EdgeInsets\.symmetric\(\s*horizontal:\s*20\s*,', 'EdgeInsets.symmetric(horizontal: 24,', content)
    content = re.sub(r'EdgeInsets\.symmetric\(\s*horizontal:\s*12\s*,', 'EdgeInsets.symmetric(horizontal: 16,', content)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def process_dir(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                replace_spacing(os.path.join(root, file))

process_dir(r'c:\Users\nicho\Documents\GitHub\saferide\lib')
print('Spacing replacements completed.')
