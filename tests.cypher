// SkinSafe extra test queries F14–F18 (Appendix F of the report)

// F14 and F15: run Q2 (Appendix C) with its first line replaced by one of these
MATCH (pa:Product {id: 'W01'}), (pb:Product {id: 'W28'})   // F14
MATCH (pa:Product {id: 'W33'}), (pb:Product {id: 'W34'})   // F15

// F16: which classes does Ethylhexyl Salicylate belong to?
MATCH (i:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(c:IngredientClass)
WHERE toLower(i.label) CONTAINS 'ethylhexyl salicylate'
RETURN i.label AS Ingredient, collect(DISTINCT c.label) AS Classes;

// F17: set both parameters in one command, then run Q4 (Appendix C)
:param {user: 'demo_sensitive', add: 'W04'}

// F18: two temporary users = User A's routine and skin type, different concern
MATCH (src:User {id: 'demo_oily'})
UNWIND [{id: 'test_aging', concern: 'Signs of aging'}, {id: 'test_oily', concern: 'Oiliness'}] AS t
CREATE (u:User {id: t.id, label: t.id, gender: src.gender})
WITH src, u, t
MATCH (src)-[r:USES]->(p:Product)
CREATE (u)-[r2:USES]->(p) SET r2 = properties(r)
WITH DISTINCT src, u, t
MATCH (src)-[:HAS_SKIN_TYPE]->(s:SkinType)
CREATE (u)-[:HAS_SKIN_TYPE]->(s)
WITH u, t
MATCH (c:Concern {label: t.concern})
CREATE (u)-[:HAS_CONCERN]->(c);
// then :param {user: 'test_aging'} and :param {user: 'test_oily'}, run Q1 for each, and clean up:
MATCH (u:User) WHERE u.id IN ['test_aging', 'test_oily'] DETACH DELETE u;
