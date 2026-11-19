// SkinSafe extra test queries F14–F20 (Appendix F of the report)

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

// F19: User C's routine, but his only sunscreen (Anessa Men SPF50+, W50) is logged at night
MATCH (src:User {id: 'demo_men'}), (spf:Product {id: 'W50'})
CREATE (u:User {id: 'test_pm_spf', label: 'test_pm_spf', gender: src.gender})
CREATE (u)-[:USES {slot: 'PM', step_order: 9}]->(spf)
WITH src, u
MATCH (src)-[r:USES]->(p:Product)
CREATE (u)-[r2:USES]->(p) SET r2 = properties(r)
WITH DISTINCT src, u
MATCH (src)-[:HAS_SKIN_TYPE]->(s:SkinType)
CREATE (u)-[:HAS_SKIN_TYPE]->(s);
// then :param {user: 'test_pm_spf', add: 'W04'} and run Q4

// F20: a temporary sunscreen with glycolic acid and two users with the AHA toner W11 (AM vs PM)
MATCH (gly:Ingredient {id: 'glycolic_acid'}), (uv:Ingredient {id: 'octinoxate'}),
      (w11:Product {id: 'W11'}), (s:SkinType {id: 'oily'})
CREATE (t:Product {id: 'TEST_SPF_AHA', label: 'TEST sunscreen SPF50 with glycolic acid', type: 'Sunscreen',
                   spf: 50, price_sgd: 5.0, price_tier: 'Budget', gender: 'Unisex', application: 'leave_on'})
CREATE (t)-[:CONTAINS]->(gly), (t)-[:CONTAINS]->(uv)
CREATE (a:User {id: 'test_am_acid', label: 'test_am_acid', gender: 'Women'}),
       (b:User {id: 'test_pm_acid', label: 'test_pm_acid', gender: 'Women'})
CREATE (a)-[:HAS_SKIN_TYPE]->(s), (b)-[:HAS_SKIN_TYPE]->(s)
CREATE (a)-[:USES {slot: 'AM', step_order: 1}]->(w11), (b)-[:USES {slot: 'PM', step_order: 1}]->(w11);
// then :param {user: 'test_am_acid', add: 'W28'} and :param {user: 'test_pm_acid', add: 'W28'}, run Q4 for each
// clean up F19 and F20:
MATCH (n) WHERE n.id IN ['test_pm_spf', 'test_am_acid', 'test_pm_acid', 'TEST_SPF_AHA'] DETACH DELETE n;
