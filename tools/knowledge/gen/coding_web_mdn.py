#!/usr/bin/env python3
"""Builds data/coding/gen_web_mdn.txt: short answers about JavaScript, CSS, HTML and DOM APIs.

Source: MDN Web Docs content, https://github.com/mdn/content (files/en-us/**/index.md).
        MDN prose is licensed CC BY-SA 2.5 by Mozilla Contributors. The opening summary of each page is
        used, with MDN macros and links turned into plain text. Pages are downloaded into
        tools/knowledge/.cache/mdn/ (not committed).

Run from the repo root:
    python3 tools/knowledge/gen/coding_web_mdn.py
"""
import html
import os
import re
import sys
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
KNOW = os.path.dirname(HERE)
CACHE = os.path.join(KNOW, ".cache", "mdn")
OUT = os.path.join(KNOW, "data", "coding", "gen_web_mdn.txt")
BASE = "https://raw.githubusercontent.com/mdn/content/main/files/en-us/"
sys.path.insert(0, KNOW)
sys.path.insert(0, HERE)
from check_data import keyset, norm  # noqa: E402
from coding_common import existing  # noqa: E402

JS = "web/javascript/reference/global_objects/"
JS_PAGES = {
    "array": """at concat copywithin entries every fill filter find findindex findlast findlastindex flat flatmap foreach
                from includes indexof isarray join keys lastindexof map of pop push reduce reduceright reverse shift
                slice some sort splice tosorted toreversed tospliced unshift values with length""",
    "string": """at charat charcodeat concat endswith includes indexof lastindexof localecompare match matchall normalize
                 padend padstart repeat replace replaceall search slice split startswith substring tolowercase
                 touppercase trim trimend trimstart length fromcharcode raw""",
    "object": """assign create defineproperty entries freeze fromentries getownpropertynames getprototypeof groupby
                 hasown is isfrozen keys seal values""",
    "math": """abs ceil floor round trunc max min pow sqrt cbrt random sign sin cos tan atan2 hypot log log10 log2 exp
               pi e""",
    "number": """isinteger isnan isfinite parsefloat parseint tofixed tostring max_safe_integer epsilon""",
    "json": "parse stringify",
    "promise": "all allsettled any race resolve reject then catch finally withresolvers",
    "map": "get set has delete clear size foreach",
    "set": "add has delete clear size union intersection difference",
    "date": "now getfullyear getmonth getdate getday gethours getminutes gettime toisostring tolocaledatestring",
    "": """parseint parsefloat isnan encodeuricomponent decodeuricomponent globalthis structuredclone""",
}
JS_TOP = """array string object math number json promise map set weakmap date regexp symbol bigint error
            typeerror syntaxerror rangeerror referenceerror boolean function proxy reflect intl""".split()
JS_OPS = """web/javascript/reference/operators/nullish_coalescing web/javascript/reference/operators/optional_chaining
            web/javascript/reference/operators/spread_syntax web/javascript/reference/operators/destructuring
            web/javascript/reference/operators/conditional_operator web/javascript/reference/operators/typeof
            web/javascript/reference/operators/instanceof web/javascript/reference/operators/strict_equality
            web/javascript/reference/operators/equality web/javascript/reference/operators/await
            web/javascript/reference/operators/new web/javascript/reference/operators/this
            web/javascript/reference/operators/delete web/javascript/reference/operators/in
            web/javascript/reference/operators/remainder web/javascript/reference/operators/exponentiation
            web/javascript/reference/operators/logical_not web/javascript/reference/operators/comma_operator
            web/javascript/reference/statements/let web/javascript/reference/statements/const
            web/javascript/reference/statements/var web/javascript/reference/statements/for...of
            web/javascript/reference/statements/for...in web/javascript/reference/statements/switch
            web/javascript/reference/statements/try...catch web/javascript/reference/statements/throw
            web/javascript/reference/statements/class web/javascript/reference/statements/async_function
            web/javascript/reference/statements/import web/javascript/reference/statements/export
            web/javascript/reference/statements/break web/javascript/reference/statements/continue
            web/javascript/reference/statements/do...while web/javascript/reference/statements/label
            web/javascript/reference/functions/arrow_functions web/javascript/reference/functions/default_parameters
            web/javascript/reference/functions/rest_parameters web/javascript/reference/functions/get
            web/javascript/reference/template_literals web/javascript/reference/strict_mode
            web/javascript/reference/classes/constructor web/javascript/reference/classes/extends
            web/javascript/reference/classes/static web/javascript/reference/classes/private_elements""".split()

CSS = "web/css/reference/properties/"
CSS_PROPS = """margin padding border border-radius width height max-width min-width max-height min-height color
background background-color background-image background-size background-position background-repeat
font-family font-size font-weight font-style line-height letter-spacing text-align text-decoration
text-transform text-shadow white-space word-break overflow overflow-wrap display position top left right
bottom z-index float clear flex flex-direction flex-wrap justify-content align-items align-content
align-self flex-grow flex-shrink flex-basis gap order grid grid-template-columns grid-template-rows
grid-template-areas grid-column grid-row grid-area place-items opacity visibility cursor box-shadow
box-sizing transform transition transition-duration animation animation-name animation-duration
filter backdrop-filter object-fit aspect-ratio outline list-style user-select pointer-events content
vertical-align inset clip-path mix-blend-mode scroll-behavior resize accent-color text-overflow
column-count isolation will-change""".split()
CSS_OTHER = """web/css/reference/at-rules/@media web/css/reference/at-rules/@keyframes web/css/reference/at-rules/@import
web/css/reference/at-rules/@font-face web/css/reference/values/calc web/css/reference/values/var
web/css/reference/values/clamp web/css/reference/values/min web/css/reference/values/max
web/css/reference/values/linear-gradient web/css/reference/values/rgb web/css/reference/values/hsl
web/css/reference/selectors/_colon_hover web/css/reference/selectors/_colon_focus web/css/reference/selectors/_colon_active
web/css/reference/selectors/_colon_nth-child web/css/reference/selectors/_colon_first-child web/css/reference/selectors/_colon_not
web/css/reference/selectors/_colon_root web/css/reference/selectors/_doublecolon_before web/css/reference/selectors/_doublecolon_after
web/css/reference/selectors/_colon_has web/css/reference/selectors/class_selectors
web/css/reference/selectors/id_selectors web/css/reference/selectors/universal_selectors""".split()

HTML = "web/html/reference/elements/"
HTML_ELEMS = """html head body title meta link script style div span p a img h1 ul ol li table tr td th thead tbody
form input button label select option textarea br hr strong em b i section article nav header footer
main aside figure figcaption video audio source canvas iframe pre code blockquote details summary
dialog template slot progress meter abbr small sub sup mark time address fieldset legend datalist
picture noscript base""".split()
HTML_ATTRS = """web/html/reference/global_attributes/class web/html/reference/global_attributes/id
web/html/reference/global_attributes/style web/html/reference/global_attributes/hidden
web/html/reference/global_attributes/tabindex web/html/reference/global_attributes/data-*
web/html/reference/global_attributes/title web/html/reference/global_attributes/lang""".split()

API = """web/api/document/queryselector web/api/document/queryselectorall web/api/document/getelementbyid
web/api/document/createelement web/api/document/getelementsbyclassname web/api/document/body
web/api/document/title web/api/document/domcontentloaded_event web/api/node/appendchild
web/api/node/removechild web/api/node/textcontent web/api/node/parentnode web/api/element/innerhtml
web/api/element/classlist web/api/element/setattribute web/api/element/getattribute web/api/element/remove
web/api/element/append web/api/element/closest web/api/element/click_event web/api/element/keydown_event
web/api/element/scrollintoview web/api/element/getboundingclientrect web/api/htmlelement/style
web/api/htmlelement/dataset web/api/htmlelement/hidden web/api/htmlelement/focus web/api/htmlinputelement/value
web/api/eventtarget/addeventlistener web/api/eventtarget/removeeventlistener web/api/event/preventdefault
web/api/event/stoppropagation web/api/event/target web/api/window/settimeout web/api/window/setinterval
web/api/window/cleartimeout web/api/window/clearinterval web/api/window/requestanimationframe
web/api/window/fetch web/api/window/localstorage web/api/window/sessionstorage web/api/window/alert
web/api/window/confirm web/api/window/prompt web/api/window/open web/api/window/location
web/api/window/innerwidth web/api/window/scrollto web/api/window/load_event web/api/window/resize_event
web/api/console/log_static web/api/console/error_static web/api/console/warn_static web/api/console/table_static
web/api/storage/setitem web/api/storage/getitem web/api/storage/removeitem web/api/response/json
web/api/response/ok web/api/response/status web/api/canvasrenderingcontext2d web/api/htmlcanvaselement/getcontext
web/api/canvasrenderingcontext2d/fillrect web/api/canvasrenderingcontext2d/drawimage
web/api/canvasrenderingcontext2d/clearrect web/api/canvasrenderingcontext2d/arc web/api/websocket
web/api/web_audio_api web/api/geolocation_api web/api/navigator/clipboard web/api/url web/api/urlsearchparams
web/api/formdata web/api/abortcontroller web/api/intersectionobserver web/api/web_workers_api
web/api/indexeddb_api web/api/notification web/api/gamepad_api web/api/fullscreen_api
web/api/element/requestfullscreen web/api/htmlmediaelement/play web/api/htmlmediaelement/pause
web/api/blob web/api/filereader web/api/customevent web/api/mutationobserver web/api/performance/now
web/api/crypto/randomuuid web/api/structuredclone web/api/broadcastchannel web/api/serial
web/api/webgl_api web/api/webgpu_api web/api/history_api web/api/service_worker_api""".split()

DATED = re.compile(r"\b(currently|right now|these days|nowadays|the current|at the moment|today's)\b", re.I)


def fetch(path):
    local = os.path.join(CACHE, path.replace("/", "__") + ".md")
    if not os.path.exists(local):
        os.makedirs(CACHE, exist_ok=True)
        try:
            with urllib.request.urlopen(BASE + path + "/index.md", timeout=30) as r:
                open(local, "wb").write(r.read())
        except Exception as ex:  # noqa: BLE001
            print("skip", path, ex, file=sys.stderr)
            open(local, "w").write("")
    return open(local, encoding="utf-8").read()


def macro(m):
    args = re.findall(r'"([^"]*)"', m.group(2))
    name = m.group(1).lower()
    if not args:
        return ""
    if name in ("jsxref", "domxref", "cssxref", "glossary", "httpheader", "svgelement", "mathmlelement"):
        text = args[1] if len(args) > 1 and args[1] else args[0]
        text = text.split("/")[-1] if name == "jsxref" and len(args) == 1 else text
        return text
    if name == "htmlelement":
        return f"<{args[1] if len(args) > 1 and args[1] else args[0]}>"
    if name == "htmlattrxref":
        return args[0]
    return ""


def summary(md):
    if not md.startswith("---"):
        return None, None
    _, front, body = md.split("---", 2)
    title = re.search(r"^title:\s*(.+)$", front, re.M)
    short = re.search(r"^short-title:\s*(.+)$", front, re.M)
    title = title.group(1).strip().strip('"') if title else ""
    short = short.group(1).strip().strip('"') if short else ""
    paras = []
    for block in re.split(r"\n\s*\n", body.strip()):
        b = block.strip()
        if b.startswith("- ") or b.startswith("1. "):
            break
        if not b or b.startswith("{{") or b.startswith(">") or b.startswith("#") or b.startswith("```"):
            if paras and (b.startswith("#") or b.startswith("```")):
                break
            continue
        paras.append(b)
        if len(" ".join(paras)) > 160:
            break
    text = " ".join(paras)
    text = re.sub(r"\{\{\s*(\w+)\s*\(([^)]*)\)\s*\}\}", macro, text)
    text = re.sub(r"\{\{[^}]*\}\}", "", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)
    text = text.replace("**", "").replace("—", ", ").replace("–", ", ")
    text = re.sub(r"(?<!\w)_([^_]+)_(?!\w)", r"\1", text)
    text = html.unescape(re.sub(r"\s+", " ", text).strip())
    text = re.split(r":\s+-\s", text)[0]
    sents = [s for s in re.split(r"(?<=[.!?])\s+", text)
             if not DATED.search(s) and not s.rstrip().endswith(":") and not re.search(r"\b(below|above|this page|this article|See )\b", s)]
    out = ""
    for s in sents:
        if len(out) + len(s) > 360:
            break
        out = (out + " " + s).strip()
    if "=>" in out or "||" in out or len(out) < 30:
        return title, None
    out = out[0].upper() + out[1:]
    return (title, short), out


entries, seen, seen_k = [], set(), set()


def add(tag, qs, a):
    keep = []
    for q in qs:
        q = re.sub(r"\s+", " ", q.lower()).strip()
        k = keyset(q)
        if not q or "?" in q or norm(q) in seen or (len(k) >= 2 and k in seen_k) or q in keep:
            continue
        if not 1 <= len(q.split()) <= 16:
            continue
        keep.append(q)
    if len(keep) < 2:
        return
    for q in keep:
        seen.add(norm(q))
        if len(keyset(q)) >= 2:
            seen_k.add(keyset(q))
    entries.append((tag, keep, a))


def main():
    w, k = existing(OUT)
    seen.update(w)
    seen_k.update(k)
    for obj, names in JS_PAGES.items():
        for n in names.split():
            path = JS + (f"{obj}/{n}" if obj else n)
            (titles, a) = summary(fetch(path))
            if not a:
                continue
            title, short = titles
            label = obj.capitalize() if obj not in ("json",) else "JSON"
            if obj == "":
                nm = short or title
                nm = nm.replace("()", "")
                qs = [f"what does {nm} do in javascript", f"javascript {nm} function", f"how do i use {nm} in js"]
            else:
                nm = n
                qs = [f"what does {obj}.{nm} do in javascript", f"javascript {label.lower()} {nm}",
                      f"how do i use {nm} on {'an' if label[0] in 'AEIOU' else 'a'} {label.lower()} in js"]
                if obj in ("math", "json", "object", "number", "promise") or "static" in title.lower():
                    qs[2] = f"how do i use {obj}.{nm} in js"
            add("coding.web.javascript", qs, a)
    for obj in JS_TOP:
        (titles, a) = summary(fetch(JS + obj))
        if a:
            add("coding.web.javascript", [f"what is {obj} in javascript", f"javascript {obj} object",
                                          f"js {obj} explained"], a)
    for path in JS_OPS:
        (titles, a) = summary(fetch(path))
        if not a:
            continue
        name = path.rsplit("/", 1)[1].replace("_", " ").replace("...", " ")
        add("coding.web.javascript", [f"what is {name} in javascript", f"javascript {name}",
                                      f"how does {name} work in js"], a)
    for p in CSS_PROPS:
        (titles, a) = summary(fetch(CSS + p))
        if a:
            words = p.replace("-", " ")
            add("coding.web.css", [f"what does {p} do in css", f"css {p} property", f"how do i use {words} in css"], a)
    for path in CSS_OTHER:
        (titles, a) = summary(fetch(path))
        if not a:
            continue
        name = path.rsplit("/", 1)[1].replace("_doublecolon_", "::").replace("_colon_", ":").replace("_", " ")
        clean = name.lstrip(":@").replace("-", " ")
        add("coding.web.css", [f"what is {name} in css", f"css {clean}", f"how do i use {clean} in css"], a)
    for el in HTML_ELEMS:
        (titles, a) = summary(fetch(HTML + el))
        if a:
            add("coding.web.html", [f"what is the {el} tag in html", f"html {el} element", f"what does <{el}> do in html"], a)
    for path in HTML_ATTRS:
        (titles, a) = summary(fetch(path))
        if a:
            name = path.rsplit("/", 1)[1].replace("-*", "")
            add("coding.web.html", [f"what is the {name} attribute in html", f"html {name} attribute",
                                    f"how do i use the {name} attribute"], a)
    for path in API:
        (titles, a) = summary(fetch(path))
        if not a:
            continue
        parts = path.split("/")[2:]
        name = ".".join(parts).replace("_static", "").replace("_event", " event").replace("_api", " api")
        name = name.replace("_", " ")
        short = parts[-1].replace("_static", "").replace("_event", " event").replace("_api", " api").replace("_", " ")
        add("coding.web.dom", [f"what is {name} in javascript", f"what does {short} do in javascript",
                               f"js {short}"], a)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("# Generated by tools/knowledge/gen/coding_web_mdn.py from MDN Web Docs (github.com/mdn/content),\n")
        fh.write("# prose by Mozilla Contributors, CC BY-SA 2.5. Do not edit by hand.\n")
        tag = None
        for t, qs, a in entries:
            if t != tag:
                fh.write(f"# tag: {t}\n")
                tag = t
            fh.write(" | ".join(qs) + " => " + a + "\n")
    print(f"wrote {len(entries)} entries to {OUT}")


if __name__ == "__main__":
    main()
