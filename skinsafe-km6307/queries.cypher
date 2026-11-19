// =====================================================================
// SkinSafe Routine Builder — queries for the intelligent function
// Data: 48 real products from Watsons Singapore (checked 16 Nov 2026)
//
// First choose the user to check (in Neo4j Browser):
//   :param {user: 'demo_oily'}        (woman, oily, acne-prone; concerns: acne, hyperpigmentation)
//   :param {user: 'demo_sensitive'}   (woman, sensitive skin; concerns: redness, signs of aging)
//   :param {user: 'demo_men'}         (man, oily, shaves daily; concerns: acne, oiliness)
//
// Rinse-off products (cleansers) stay on the skin for about a minute, so they only
// trigger High-severity conflicts, never over-layering or the sunscreen rule
// (p.application = 'rinse_off' | 'leave_on', set in import.cypher).
//
// Reusable inference pattern used everywhere:
//   (p:Product)-[:CONTAINS]->(i:Ingredient)-[:IS_A]->(:IngredientClass)
//              -[:SUBCLASS_OF*0..5]->(c:IngredientClass)
// A product inherits every rule attached to ANY ancestor class of any of
// its ingredients, so each rule is written once, at class level.
// =====================================================================



// ---------------------------------------------------------------------
// Q0  ROUTINE CHECK-UP — one user-friendly table, one row per finding
// ---------------------------------------------------------------------
CALL () {   // "()" = this subquery imports no outer variables (required style in Cypher 25)
  // (1) Ingredient conflicts between two products in the same time slot
  MATCH (u:User {id: $user})-[r1:USES]->(p1:Product)-[:CONTAINS]->(i1:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(c1:IngredientClass)
  MATCH (u)-[r2:USES]->(p2:Product)-[:CONTAINS]->(i2:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(c2:IngredientClass)
  MATCH (c1)-[k:CONFLICTS_WITH]->(c2)
  WHERE r1.slot = r2.slot AND p1 <> p2
    AND ((p1.application = 'leave_on' AND p2.application = 'leave_on') OR k.severity_rank >= 3)
  WITH r1.slot AS Time, p1, p2, k, collect(DISTINCT i1.label + ' + ' + i2.label) AS pairs
  RETURN 'Conflict' AS Issue, Time,
         p1.label + '  +  ' + p2.label AS Products,
         reduce(s = '', x IN pairs | s + CASE s WHEN '' THEN '' ELSE '; ' END + x) AS Ingredients,
         k.severity AS Risk, k.severity_rank AS rank, k.reason AS Why, k.advice AS What_to_do
  UNION ALL
  // (2) Sun-sensitising ingredient but no real sunscreen (SPF 30+) in the morning.
  //     A UV filter alone is not enough: titanium dioxide can be a whitener in a serum,
  //     and an aftershave may contain a UV filter without being a sunscreen.
  MATCH (u:User {id: $user})-[r:USES]->(p:Product)-[:CONTAINS]->(i:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(c:IngredientClass)-[q:REQUIRES]->(need:IngredientClass)
  WHERE p.application = 'leave_on'
  AND NOT EXISTS {
    MATCH (u)-[:USES {slot: 'AM'}]->(sp:Product)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(need)
    WHERE sp.spf >= 30
  }
  WITH p, q, collect(DISTINCT i.label) AS ings
  RETURN 'Missing sun protection' AS Issue, 'AM' AS Time, p.label AS Products,
         reduce(s = '', x IN ings | s + CASE s WHEN '' THEN '' ELSE ', ' END + x) AS Ingredients,
         'Medium' AS Risk, 2 AS rank, q.reason AS Why, q.advice AS What_to_do
  UNION ALL
  // (3) Over-layering: two products of a "no_stack" class in the same slot
  MATCH (u:User {id: $user})-[r:USES]->(p:Product)-[:CONTAINS]->(i:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(c:IngredientClass {no_stack: true})
  WHERE p.application = 'leave_on'
  WITH r.slot AS slot, c, collect(DISTINCT p.label) AS prods, collect(DISTINCT i.label) AS ings
  WHERE size(prods) > 1
  RETURN 'Over-layering' AS Issue, slot AS Time,
         reduce(s = '', x IN prods | s + CASE s WHEN '' THEN '' ELSE '  +  ' END + x) AS Products,
         reduce(s = '', x IN ings  | s + CASE s WHEN '' THEN '' ELSE ', ' END + x) AS Ingredients,
         'Medium' AS Risk, 2 AS rank, c.stack_reason AS Why,
         'Keep one ' + c.label + ' product in this slot; move the other to the other slot or alternate days.' AS What_to_do
  UNION ALL
  // (4) Ingredient not suited to the user's skin type
  MATCH (u:User {id: $user})-[:HAS_SKIN_TYPE]->(s:SkinType)
  MATCH (u)-[r:USES]->(p:Product)-[:CONTAINS]->(i:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(c:IngredientClass)-[w:CAUTION_FOR]->(s)
  WITH s, r.slot AS Time, p, c, w, collect(DISTINCT i.label) AS ings
  RETURN 'Skin-type caution (' + s.label + ')' AS Issue, Time, p.label AS Products,
         c.label + ': ' + reduce(x = '', y IN ings | x + CASE x WHEN '' THEN '' ELSE ', ' END + y) AS Ingredients,
         'Medium' AS Risk, 2 AS rank, w.reason AS Why, w.advice AS What_to_do
  UNION ALL
  // (5) Good news: popular "conflicts" that are actually fine (myth busting / order tips)
  MATCH (u:User {id: $user})-[r1:USES]->(p1:Product)-[:CONTAINS]->(i1:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(c1:IngredientClass)
  MATCH (u)-[r2:USES]->(p2:Product)-[:CONTAINS]->(i2:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(c2:IngredientClass)
  MATCH (c1)-[k:COMPATIBLE_WITH]->(c2)
  WHERE r1.slot = r2.slot AND p1 <> p2
  WITH r1.slot AS Time, p1, p2, k, collect(DISTINCT i1.label + ' + ' + i2.label) AS pairs
  RETURN 'Good to know' AS Issue, Time, p1.label + '  +  ' + p2.label AS Products,
         reduce(s = '', x IN pairs | s + CASE s WHEN '' THEN '' ELSE '; ' END + x) AS Ingredients,
         'OK (' + k.evidence + ')' AS Risk, 0 AS rank, k.reason AS Why, k.advice AS What_to_do
}
// Gentle, advice-style labels instead of alarm words
RETURN Issue, Time, Products, Ingredients,
       CASE Risk WHEN 'High' THEN 'Please separate'
                 WHEN 'Medium' THEN 'Worth adjusting'
                 WHEN 'Low' THEN 'Small tip'
                 ELSE 'Good to know' END AS Advice_level,
       Why, What_to_do
ORDER BY rank DESC, Time, Issue;

// ---------------------------------------------------------------------
// Q1  SMART SUBSTITUTION — for each product in a conflict, suggest
//     products of the same type that cover the same skin concerns and are
//     safe with EVERY other product in that slot:
//       - no conflict (inherited rules included)
//       - no over-layering of a no_stack class
//       - no new problem (e.g. a sun-sensitising product without a morning SPF 30+)
//       - nothing the user's skin type should be cautious with
//     Ranking inside each price tier: the user's own Skinfie Lab concerns
//     (HAS_CONCERN) covered -> benefit coverage -> segment (own gender or
//     unisex first; the other segment stays eligible, with a note) -> price.
//     Output: up to 2 best picks in EACH price tier
//     (Budget < S$20, Mid S$20–45, Premium > S$45).
// ---------------------------------------------------------------------
MATCH (u:User {id: $user})-[r1:USES]->(p1:Product)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(c1:IngredientClass)
MATCH (u)-[r2:USES]->(p2:Product)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(c2:IngredientClass)
MATCH (c1)-[k0:CONFLICTS_WITH]-(c2)
WHERE r1.slot = r2.slot AND p1 <> p2
  AND ((p1.application = 'leave_on' AND p2.application = 'leave_on') OR k0.severity_rank >= 3)
WITH DISTINCT u, r1.slot AS slot, p1, p2
MATCH (u)-[ro:USES]->(other:Product)
WHERE ro.slot = slot AND other <> p1
WITH u, slot, p1, p2, collect(DISTINCT other) AS keep
MATCH (p1)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(:IngredientClass)-[:TARGETS]->(need:Concern)
WITH u, slot, p1, p2, keep, collect(DISTINCT need) AS needs
MATCH (alt:Product)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(:IngredientClass)-[:TARGETS]->(k:Concern)
WHERE k IN needs AND alt <> p1 AND NOT alt IN keep AND NOT (u)-[:USES]->(alt)
  AND alt.type = p1.type
WITH u, slot, p1, p2, keep, needs, alt, collect(DISTINCT k.label) AS covered
// each side in its own MATCH: within one pattern Neo4j never reuses a relationship
WHERE NOT EXISTS {           // no conflict with a product that stays
  MATCH (alt)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(a:IngredientClass)
  MATCH (a)-[k:CONFLICTS_WITH]-(b:IngredientClass)
  MATCH (o:Product)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(b)
  WHERE o IN keep
    AND ((o.application = 'leave_on' AND alt.application = 'leave_on') OR k.severity_rank >= 3)
}
AND NOT EXISTS {             // no over-layering with a product that stays
  MATCH (alt)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(a:IngredientClass {no_stack: true})
  MATCH (o:Product)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(a)
  WHERE o IN keep AND o.application = 'leave_on' AND alt.application = 'leave_on'
}
AND NOT EXISTS {             // no new problem: sun-sensitising without a morning SPF 30+
  MATCH (alt)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(:IngredientClass)-[:REQUIRES]->(nd:IngredientClass)
  WHERE alt.application = 'leave_on'
    AND NOT EXISTS {
      MATCH (u)-[:USES {slot: 'AM'}]->(sp:Product)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(nd)
      WHERE sp.spf >= 30
    }
}
AND NOT EXISTS {             // nothing the user's skin type should be cautious with
  MATCH (u)-[:HAS_SKIN_TYPE]->(s:SkinType)
  MATCH (alt)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(:IngredientClass)-[:CAUTION_FOR]->(s)
}
// ranking: the user's own concerns (from Skinfie Lab) first, then benefit coverage,
// then products for the user's segment or unisex, then price
WITH slot, p1, p2, needs, alt, covered,
     COLLECT { MATCH (u)-[:HAS_CONCERN]->(uc:Concern)
               MATCH (alt)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(:IngredientClass)-[:TARGETS]->(uc)
               RETURN DISTINCT uc.label } AS mine,
     CASE WHEN alt.gender IN [u.gender, 'Unisex'] THEN 0 ELSE 1 END AS other_seg
ORDER BY size(mine) DESC, size(covered) DESC, other_seg ASC, alt.price_sgd ASC
WITH slot, p1, p2, alt.price_tier AS tier,
     collect({alt: alt, covered: covered, mine: mine, other_seg: other_seg,
              coverage: 100.0 * size(covered) / size(needs)})[0..2] AS picks
UNWIND picks AS pick
RETURN slot AS Time, p1.label AS Instead_of, p2.label AS Because_it_clashes_with,
       tier AS Price_tier, pick.alt.label AS Try_this, pick.alt.price_sgd AS Price_SGD,
       pick.mine AS Your_concerns,
       pick.covered AS Same_benefits,
       toString(toInteger(round(pick.coverage))) + '%' AS Benefit_coverage,
       CASE pick.other_seg WHEN 1
            THEN 'Marketed for ' + toLower(pick.alt.gender) + '; suggested for its ingredients'
            ELSE '' END AS Note
ORDER BY Time, Instead_of,
         CASE tier WHEN 'Budget' THEN 1 WHEN 'Mid' THEN 2 ELSE 3 END,
         size(pick.mine) DESC, pick.coverage DESC, pick.other_seg, Price_SGD;


// ---------------------------------------------------------------------
// Q2  EXPLAIN ONE PAIR — "Can I use product A with product B?"
// ---------------------------------------------------------------------
MATCH (pa:Product {id: 'W01'}), (pb:Product {id: 'W11'})   // CeraVe retinol serum vs The Ordinary glycolic toner
OPTIONAL MATCH (pa)-[:CONTAINS]->(i1:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(c1:IngredientClass)-[k]-(c2:IngredientClass)<-[:SUBCLASS_OF*0..5]-(:IngredientClass)<-[:IS_A]-(i2:Ingredient)<-[:CONTAINS]-(pb)
WHERE type(k) IN ['CONFLICTS_WITH', 'COMPATIBLE_WITH']
RETURN pa.label AS Product_A, pb.label AS Product_B,
       CASE WHEN k IS NULL THEN 'No known interaction' ELSE type(k) END AS Verdict,
       i1.label + ' (' + c1.label + ')' AS From_A, i2.label + ' (' + c2.label + ')' AS From_B,
       k.severity AS Risk, k.reason AS Why, k.advice AS What_to_do, k.source AS Source;


// ---------------------------------------------------------------------
// Q3  MERCHANDISING INSIGHTS for the retailer (degree-style statistics)
// ---------------------------------------------------------------------
// Q3a Which products are involved in the most conflict rules?
MATCH (p:Product)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(:IngredientClass)-[k:CONFLICTS_WITH]-(:IngredientClass)
RETURN p.label AS Product, p.type AS Type, count(DISTINCT k) AS Conflict_rules, collect(DISTINCT k.rule_id) AS Rules
ORDER BY Conflict_rules DESC, Product LIMIT 10;

// Q3b Products marketed for sensitive skin that still contain a sensitive-skin caution ingredient
MATCH (p:Product)-[:CONTAINS]->(i:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(c:IngredientClass)-[:CAUTION_FOR]->(:SkinType {id: 'sensitive'})
WHERE toLower(p.label) CONTAINS 'sensitive' OR toLower(p.data_note) CONTAINS 'sensitive'
RETURN p.label AS Product, collect(DISTINCT c.label + ' (' + i.label + ')') AS Caution_ingredients;

// ---------------------------------------------------------------------
// Q4  COMPLETE THE ROUTINE — when a user adds a (featured) product, suggest
//     what goes with it, using the same class-level rules:
//       REQUIRES        -> a sunscreen with SPF 30+
//       COMPATIBLE_WITH -> a supporting product (e.g. ceramide moisturiser)
//     Only needs the routine does not cover yet; every suggestion passes the
//     same safety filters as Q1 (no conflict, no over-layering, skin type).
//     Gender only ranks (own segment or unisex first), it never excludes.
//   :param {user: 'demo_men', add: 'W04'}   (Target Pro Granactive Retinoid 1%, a Watsons own brand)
// ---------------------------------------------------------------------
MATCH (u:User {id: $user}), (add:Product {id: $add})
MATCH (add)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(c:IngredientClass)-[rel:REQUIRES|COMPATIBLE_WITH]->(need:IngredientClass)
WITH DISTINCT u, add, c, rel, need
WHERE NOT (need)-[:SUBCLASS_OF*0..5]->(:IngredientClass {label: 'Active ingredient'})
AND NOT EXISTS {             // the routine already covers this need
  MATCH (u)-[:USES]->(have:Product)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(need)
  WHERE have <> add AND (type(rel) = 'COMPATIBLE_WITH' OR have.spf >= 30)
}
MATCH (alt:Product)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(need)
WHERE alt <> add AND NOT (u)-[:USES]->(alt)
  AND (type(rel) = 'COMPATIBLE_WITH' OR alt.spf >= 30)
  AND alt.type <> add.type
  AND (type(rel) = 'REQUIRES' OR alt.type <> 'Sunscreen')
WITH DISTINCT u, add, c, rel, need, alt
WHERE NOT EXISTS {
  MATCH (u)-[:HAS_SKIN_TYPE]->(s:SkinType)
  MATCH (alt)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(:IngredientClass)-[:CAUTION_FOR]->(s)
}
AND NOT EXISTS {             // only Medium/High conflicts block a suggestion
  MATCH (alt)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(a:IngredientClass)
  MATCH (a)-[k:CONFLICTS_WITH]-(b:IngredientClass) WHERE k.severity_rank >= 2
  MATCH (add)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(b)
}
AND NOT EXISTS {
  MATCH (alt)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(a:IngredientClass {no_stack: true})
  MATCH (add)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(a)
}
// promoted items may be ranked first HERE, after every safety filter;
// products for the user's segment or unisex come first, others stay eligible
WITH add, c, rel, need, alt,
     CASE WHEN alt.gender IN [u.gender, 'Unisex'] THEN 0 ELSE 1 END AS other_seg
ORDER BY other_seg, alt.price_sgd
WITH add, c, rel, need, collect({alt: alt, other_seg: other_seg})[0..2] AS picks
UNWIND picks AS pick
WITH add, c, rel, need, pick.alt AS alt, pick.other_seg AS other_seg
// a Low-severity clash becomes a usage tip
OPTIONAL MATCH (alt)-[:CONTAINS]->(ia:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(:IngredientClass)-[low:CONFLICTS_WITH {severity_rank: 1}]-(:IngredientClass)<-[:SUBCLASS_OF*0..5]-(:IngredientClass)<-[:IS_A]-(ib:Ingredient)<-[:CONTAINS]-(add)
WITH add, c, rel, need, alt, other_seg,
     collect(DISTINCT 'Contains ' + ia.label + ', a minor clash with ' + ib.label + ': use them at different times of day.') AS tips
RETURN add.label AS Featured_product, c.label + ' -> ' + need.label AS Link, type(rel) AS Rule,
       alt.label AS Goes_well_with, alt.price_sgd AS Price_SGD, alt.price_tier AS Tier,
       coalesce(rel.advice, rel.reason) AS Why, tips AS Usage_tip,
       CASE other_seg WHEN 1
            THEN 'Marketed for ' + toLower(alt.gender) + '; suggested for its ingredients'
            ELSE '' END AS Note;


// =====================================================================
// VISUALISATION QUERIES (return paths so Neo4j Browser draws a graph)
// =====================================================================

// V1  The user's routine with the conflict paths
MATCH path = (u:User {id: $user})-[r1:USES]->(p1:Product)-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(c1:IngredientClass)-[k:CONFLICTS_WITH]-(c2:IngredientClass)<-[:SUBCLASS_OF*0..5]-(:IngredientClass)<-[:IS_A]-(:Ingredient)<-[:CONTAINS]-(p2:Product)<-[r2:USES]-(u)
WHERE r1.slot = r2.slot AND p1.id < p2.id      // each conflicting pair once (not A-B and B-A)
  AND ((p1.application = 'leave_on' AND p2.application = 'leave_on') OR k.severity_rank >= 3)
RETURN path;

// V2  Ontology overview: class hierarchy + class-level rules
MATCH path = (:IngredientClass)-[:SUBCLASS_OF|CONFLICTS_WITH|COMPATIBLE_WITH|REQUIRES]->(:IngredientClass)
RETURN path;

// V3  Why a substitute fits: product -> ingredient -> class -> concern it addresses
MATCH path = (:Product {id: 'W23'})-[:CONTAINS]->(:Ingredient)-[:IS_A]->(:IngredientClass)-[:SUBCLASS_OF*0..5]->(:IngredientClass)-[:TARGETS]->(:Concern)
RETURN path;
