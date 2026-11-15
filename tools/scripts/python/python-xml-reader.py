# @title Read XML Data
# @category Files and data
# @kind Console program
# @where Save as xml_reader.py and run: python3 xml_reader.py
# @keywords python xml, python elementtree, python parse xml, python xml attributes
# @about Reads XML (a tag-based data format used by RSS feeds and many apps) with ElementTree.

import xml.etree.ElementTree as ET

XML = """
<library>
  <book id="1" year="1997">
    <title>Harry Potter and the Philosopher's Stone</title>
    <author>J.K. Rowling</author>
    <pages>223</pages>
  </book>
  <book id="2" year="1937">
    <title>The Hobbit</title>
    <author>J.R.R. Tolkien</author>
    <pages>310</pages>
  </book>
  <book id="3" year="2008">
    <title>The Hunger Games</title>
    <author>Suzanne Collins</author>
    <pages>374</pages>
  </book>
</library>
"""

root = ET.fromstring(XML)
print("The root tag is:", root.tag)

for book in root.findall("book"):
    title = book.find("title").text
    author = book.findtext("author")
    pages = int(book.findtext("pages"))
    year = book.get("year")  # attributes are inside the tag itself
    print(f"{title} by {author} ({year}), {pages} pages")

total = sum(int(b.findtext("pages")) for b in root.iter("book"))
print("Total pages:", total)

# You can also build XML and turn it back into text
new = ET.SubElement(root, "book", id="4", year="2026")
ET.SubElement(new, "title").text = "My First Python Book"
print("\nNew book added:", ET.tostring(new, encoding="unicode"))
