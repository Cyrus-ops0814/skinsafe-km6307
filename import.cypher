// =====================================================================
// SkinSafe Routine Builder — data import script (Neo4j 5.x)
// Put all CSV files in the database's "import" folder
// (Neo4j Desktop: ... next to the database > Open folder > Import).
// Alternative (as in class): publish each Google Sheet as CSV and replace
// 'file:///xx.csv' with the published URL.
// Run the statements one by one, or paste the whole script into Neo4j Browser
// with "Enable multi statement query editor" turned on.
//
// Design convention (Chris' approach):
//   node LABEL = top class, node.type = most specific class
//   edge TYPE  = relation, edge.type = most specific relation
// =====================================================================

// ---------- 0. Constraints ----------
CREATE CONSTRAINT product_id IF NOT EXISTS FOR (n:Product) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT ingredient_id IF NOT EXISTS FOR (n:Ingredient) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT class_id IF NOT EXISTS FOR (n:IngredientClass) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT concern_id IF NOT EXISTS FOR (n:Concern) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT skintype_id IF NOT EXISTS FOR (n:SkinType) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT user_id IF NOT EXISTS FOR (n:User) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT brand_id IF NOT EXISTS FOR (n:Brand) REQUIRE n.id IS UNIQUE;

// ---------- 1. Ingredient class hierarchy ----------
LOAD CSV WITH HEADERS FROM 'file:///01_ingredient_classes.csv' AS r
MERGE (c:IngredientClass {id: trim(r.class_id)})
ON CREATE SET c.label = r.label, c.label_zh = r.label_zh, c.type = trim(r.class_id),
              c.no_stack = coalesce(toBoolean(r.no_stack), false), c.stack_reason = r.stack_reason;

LOAD CSV WITH HEADERS FROM 'file:///01_ingredient_classes.csv' AS r
WITH r WHERE r.parent_id IS NOT NULL AND trim(r.parent_id) <> ''
MATCH (c:IngredientClass {id: trim(r.class_id)}), (p:IngredientClass {id: trim(r.parent_id)})
MERGE (c)-[:SUBCLASS_OF {type: 'subClassOf'}]->(p);

// ---------- 2. Ingredients (instances) -> IS_A -> class ----------
LOAD CSV WITH HEADERS FROM 'file:///02_ingredients.csv' AS r
MATCH (c:IngredientClass {id: trim(r.class_id)})
MERGE (i:Ingredient {id: trim(r.ingredient_id)})
ON CREATE SET i.label = r.label, i.label_zh = r.label_zh, i.type = trim(r.class_id),
              i.aliases = CASE WHEN r.aliases IS NULL THEN [] ELSE split(r.aliases, '|') END
MERGE (i)-[:IS_A {type: 'type'}]->(c);

// ---------- 3. Concerns and skin types ----------
LOAD CSV WITH HEADERS FROM 'file:///03_concerns.csv' AS r
MERGE (n:Concern {id: trim(r.concern_id)})
ON CREATE SET n.label = r.label, n.label_zh = r.label_zh, n.type = 'Skin_concern';

LOAD CSV WITH HEADERS FROM 'file:///04_skin_types.csv' AS r
MERGE (n:SkinType {id: trim(r.skin_type_id)})
ON CREATE SET n.label = r.label, n.label_zh = r.label_zh, n.type = 'Skin_type';

// ---------- 4. Class-level knowledge (rules) ----------
LOAD CSV WITH HEADERS FROM 'file:///05_class_targets_concern.csv' AS r
MATCH (c:IngredientClass {id: trim(r.class_id)}), (k:Concern {id: trim(r.concern_id)})
MERGE (c)-[:TARGETS {type: 'targets'}]->(k);

LOAD CSV WITH HEADERS FROM 'file:///06_class_interaction_rules.csv' AS r
WITH r WHERE r.rel_type = 'CONFLICTS_WITH'
MATCH (a:IngredientClass {id: trim(r.class_a)}), (b:IngredientClass {id: trim(r.class_b)})
MERGE (a)-[x:CONFLICTS_WITH {rule_id: r.rule_id}]->(b)
ON CREATE SET x.type = 'conflictsWith', x.severity = r.severity, x.severity_rank = toInteger(r.severity_rank),
              x.evidence = r.evidence, x.reason = r.reason, x.advice = r.advice,
              x.source = r.source, x.source_url = r.source_url;

LOAD CSV WITH HEADERS FROM 'file:///06_class_interaction_rules.csv' AS r
WITH r WHERE r.rel_type = 'COMPATIBLE_WITH'
MATCH (a:IngredientClass {id: trim(r.class_a)}), (b:IngredientClass {id: trim(r.class_b)})
MERGE (a)-[x:COMPATIBLE_WITH {rule_id: r.rule_id}]->(b)
ON CREATE SET x.type = 'compatibleWith', x.evidence = r.evidence, x.reason = r.reason, x.advice = r.advice,
              x.source = r.source, x.source_url = r.source_url;

LOAD CSV WITH HEADERS FROM 'file:///07_class_requires.csv' AS r
MATCH (a:IngredientClass {id: trim(r.class_id)}), (b:IngredientClass {id: trim(r.required_class)})
MERGE (a)-[x:REQUIRES]->(b)
ON CREATE SET x.type = 'requiresSunProtection', x.reason = r.reason, x.advice = r.advice,
              x.source = r.source, x.source_url = r.source_url;

LOAD CSV WITH HEADERS FROM 'file:///08_class_skin_type_rules.csv' AS r
WITH r WHERE r.rel_type = 'CAUTION_FOR'
MATCH (a:IngredientClass {id: trim(r.class_id)}), (s:SkinType {id: trim(r.skin_type_id)})
MERGE (a)-[x:CAUTION_FOR]->(s)
ON CREATE SET x.type = 'cautionFor', x.reason = r.reason, x.advice = r.advice,
              x.source = r.source, x.source_url = r.source_url;

LOAD CSV WITH HEADERS FROM 'file:///08_class_skin_type_rules.csv' AS r
WITH r WHERE r.rel_type = 'RECOMMENDED_FOR'
MATCH (a:IngredientClass {id: trim(r.class_id)}), (s:SkinType {id: trim(r.skin_type_id)})
MERGE (a)-[x:RECOMMENDED_FOR]->(s)
ON CREATE SET x.type = 'recommendedFor', x.reason = r.reason, x.advice = r.advice,
              x.source = r.source, x.source_url = r.source_url;

// ---------- 5. Products, brands, ingredients in products ----------
LOAD CSV WITH HEADERS FROM 'file:///09_products.csv' AS r
MERGE (p:Product {id: trim(r.product_id)})
ON CREATE SET p.label = r.label, p.type = r.category, p.price_sgd = toFloat(r.price_sgd),
              p.gender = r.gender, p.spf = toInteger(r.spf), p.price_tier = r.price_tier,
              p.retailer = r.retailer, p.url = r.url, p.data_note = r.data_note
WITH p, r WHERE r.brand IS NOT NULL AND trim(r.brand) <> ''
MERGE (b:Brand {id: trim(r.brand)}) ON CREATE SET b.label = trim(r.brand), b.type = 'Brand'
MERGE (p)-[:HAS_BRAND {type: 'hasBrand'}]->(b);

LOAD CSV WITH HEADERS FROM 'file:///10_product_ingredients.csv' AS r
MATCH (p:Product {id: trim(r.product_id)}), (i:Ingredient {id: trim(r.ingredient_id)})
MERGE (p)-[:CONTAINS {type: 'contains'}]->(i);

// Rinse-off vs leave-on: cleansers are washed off within about a minute,
// so the queries treat them differently (derived from the product type)
MATCH (p:Product)
SET p.application = CASE WHEN p.type = 'Cleanser' THEN 'rinse_off' ELSE 'leave_on' END;

// ---------- 6. Users and their routines ----------
LOAD CSV WITH HEADERS FROM 'file:///11_users.csv' AS r
MERGE (u:User {id: trim(r.user_id)})
ON CREATE SET u.label = r.label, u.type = 'User', u.gender = r.gender
WITH u, r
MATCH (s:SkinType {id: trim(r.skin_type_id)})
MERGE (u)-[:HAS_SKIN_TYPE {type: 'hasSkinType'}]->(s)
WITH u, r
UNWIND split(r.concern_ids, '|') AS cid
MATCH (k:Concern {id: trim(cid)})
MERGE (u)-[:HAS_CONCERN {type: 'hasConcern'}]->(k);

LOAD CSV WITH HEADERS FROM 'file:///12_user_routines.csv' AS r
MATCH (u:User {id: trim(r.user_id)}), (p:Product {id: trim(r.product_id)})
MERGE (u)-[x:USES {slot: trim(r.slot)}]->(p)
ON CREATE SET x.type = 'uses', x.step_order = toInteger(r.step_order);

// ---------- 7. Check ----------
MATCH (n) RETURN labels(n)[0] AS NodeLabel, count(*) AS Count ORDER BY NodeLabel;
