# SkinSafe Routine Builder – KM6307 Final Project (Cai Yuqing)

A Neo4j knowledge graph that checks skincare routines for ingredient conflicts and suggests routine-safe substitutes and companions for the Watsons Singapore app.

## Files
| File | Content |
| --- | --- |
| `csv/` | The 12 CSV files: ingredient classes, ingredients, concerns, skin types, 48 products, users, product–ingredient links, rules and routines |
| `import.cypher` | Import with `LOAD CSV` (local Neo4j; put the CSV files in the database's import folder) |
| `import_aura.cypher` | Same import with the rows written inline (`UNWIND`), for AuraDB, which cannot read local files |
| `queries.cypher` | Q0–Q4 and V1–V3 (Appendix C of the report) and the future-extension sketches H1–H2 (Appendix H) |
| `tests.cypher` | Extra test queries F14–F20 from Appendix F (F18–F20 create temporary test data and delete it afterwards) |

## How to reproduce
1. Run `import_aura.cypher` (AuraDB) or `import.cypher` (local). Expected result: 189 nodes, 486 relationships.
2. Set parameters in a separate command, e.g. `:param {user: 'demo_oily'}` (also `demo_sensitive`, `demo_men`); Q4 needs `:param {user: 'demo_men', add: 'W04'}`.
3. Run the queries in `queries.cypher`; outputs should match Appendix E.

Data: product pages on watsons.com.sg, checked 16 November 2026. Rules: sources listed in Appendix A of the report.
