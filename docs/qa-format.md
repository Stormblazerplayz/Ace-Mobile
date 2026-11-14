# The ace-qa/1 answer bank format

Ace on the iPad and Ace V4 in Nimbus on the PC share this format, so answers can move between them.

```json
{
  "format": "ace-qa/1",
  "version": 1,
  "source": "builtin",
  "count": 2,
  "entries": [
    {
      "id": "space.moon-distance",
      "tag": "space",
      "q": ["how far is the moon", "distance to the moon"],
      "a": ["The Moon is about 384,400 km away.", "About 384,400 km, or 238,900 miles."]
    }
  ]
}
```

- **id:** unique text, like `topic.short-name`. Learned answers start with where they came from, like `taught.` or `web.`
- **tag:** the topic (space, animals, math, ace, feelings, and so on).
- **q:** different ways to ask. More wordings make matching better.
- **a:** one or more answers. Ace picks one at random so it doesn't sound the same every time.
- Optional on learned entries: **source** (taught, web), **updated** (ISO date), **url** (where a web answer came from).

Ace saves what it learns in `learned_qa.json` in the same format.
