import sys

filename = "landing.html"
with open(filename, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# The start index is 2512 (which is line 2513) and end index is 2608 (which is line 2609)
start_idx = 2513 - 1
end_idx = 2609 - 1

replacement = [
    '          <div class="ss-banner-body">\n',
    '            <img src="images/banner-img-2.jpg" alt="Amar Thikana Billboard" style="width: 100%; border-radius: 20px; box-shadow: var(--shadow); object-fit: cover; margin-top: 20px;">\n',
    '          </div>\n'
]

new_lines = lines[:start_idx] + replacement + lines[end_idx+1:]

with open(filename, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
