# @title Grade Average Calculator
# @category Math and school
# @kind Console program
# @where Save as grades.py and run: python3 grades.py
# @keywords python grade average, python gpa calculator, python weighted average, python report card
# @about Works out your average in each class (with weighted categories) and an overall GPA.

LETTERS = [(90, "A", 4.0), (80, "B", 3.0), (70, "C", 2.0), (60, "D", 1.0), (0, "F", 0.0)]


def letter_for(score):
    for cutoff, letter, points in LETTERS:
        if score >= cutoff:
            return letter, points
    return "F", 0.0


def ask_scores(label):
    text = input(f"  {label} scores separated by spaces (Enter to skip): ").split()
    return [float(t) for t in text if t.replace(".", "", 1).isdigit()]


WEIGHTS = {"Tests": 0.5, "Homework": 0.3, "Projects": 0.2}  # must add up to 1
report = []
while True:
    subject = input("\nClass name (Enter when done): ").strip()
    if not subject:
        break
    total, used = 0.0, 0.0
    for category, weight in WEIGHTS.items():
        scores = ask_scores(category)
        if scores:
            total += sum(scores) / len(scores) * weight
            used += weight
    if used:
        average = total / used  # if a category was skipped, spread its weight out
        report.append((subject, average) + letter_for(average))

if report:
    print("\n=== Report Card ===")
    for subject, average, letter, _ in report:
        print(f"{subject:<15} {average:6.1f}  {letter}")
    gpa = sum(points for *_, points in report) / len(report)
    print(f"GPA: {gpa:.2f}")
