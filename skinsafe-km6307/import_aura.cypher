// =====================================================================
// SkinSafe — import script for NEO4J AURA (cloud)
// Same logic as import.cypher, but the CSV data is written inside the script
// (UNWIND [...] AS r instead of LOAD CSV), because Aura cannot read files on
// your computer. For the report, quote import.cypher (the LOAD CSV version).
//
// How to run: Aura console > Connect > Query, paste this whole file, run.
// If the editor only runs one statement at a time, run it section by section
// (each statement ends with a semicolon).
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
UNWIND [
  {class_id: 'Skincare_ingredient', label: 'Skincare ingredient', label_zh: '护肤成分', parent_id: null, no_stack: null, stack_reason: null},
  {class_id: 'Active_ingredient', label: 'Active ingredient', label_zh: '活性成分', parent_id: 'Skincare_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Retinoid', label: 'Retinoid', label_zh: '维A类', parent_id: 'Active_ingredient', no_stack: 'true', stack_reason: 'Use only one retinoid product per routine slot; layering retinoids raises irritation without clear extra benefit.'},
  {class_id: 'Retinol_family', label: 'Retinol family', label_zh: '视黄醇类（化妆品级）', parent_id: 'Retinoid', no_stack: null, stack_reason: null},
  {class_id: 'Retinoic_acid', label: 'Retinoic acid', label_zh: '维A酸（处方级）', parent_id: 'Retinoid', no_stack: null, stack_reason: null},
  {class_id: 'Synthetic_retinoid', label: 'Synthetic retinoid', label_zh: '合成维A类（阿达帕林）', parent_id: 'Retinoid', no_stack: null, stack_reason: null},
  {class_id: 'Exfoliating_acid', label: 'Exfoliating acid', label_zh: '去角质酸', parent_id: 'Active_ingredient', no_stack: 'true', stack_reason: 'Use only one exfoliating acid product per routine slot to avoid over-exfoliation.'},
  {class_id: 'AHA', label: 'Alpha hydroxy acid (AHA)', label_zh: '果酸 AHA', parent_id: 'Exfoliating_acid', no_stack: null, stack_reason: null},
  {class_id: 'BHA', label: 'Beta hydroxy acid (BHA)', label_zh: '水杨酸 BHA', parent_id: 'Exfoliating_acid', no_stack: null, stack_reason: null},
  {class_id: 'PHA', label: 'Polyhydroxy acid (PHA)', label_zh: '多羟基酸 PHA', parent_id: 'Exfoliating_acid', no_stack: null, stack_reason: null},
  {class_id: 'Vitamin_C', label: 'Vitamin C', label_zh: '维C类', parent_id: 'Active_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'L_ascorbic_acid', label: 'L-ascorbic acid (pure vitamin C)', label_zh: '纯维C（左旋维C）', parent_id: 'Vitamin_C', no_stack: null, stack_reason: null},
  {class_id: 'Vitamin_C_derivative', label: 'Vitamin C derivative', label_zh: '维C衍生物', parent_id: 'Vitamin_C', no_stack: null, stack_reason: null},
  {class_id: 'Benzoyl_peroxide', label: 'Benzoyl peroxide', label_zh: '过氧化苯甲酰', parent_id: 'Active_ingredient', no_stack: 'true', stack_reason: 'Use only one benzoyl peroxide product per routine slot.'},
  {class_id: 'Niacinamide', label: 'Niacinamide', label_zh: '烟酰胺', parent_id: 'Active_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Azelaic_acid', label: 'Azelaic acid', label_zh: '壬二酸', parent_id: 'Active_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Peptide', label: 'Peptide', label_zh: '多肽', parent_id: 'Active_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Retinol_alternative', label: 'Retinol alternative (plant-based)', label_zh: '植物类A醇替代成分', parent_id: 'Active_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Supporting_ingredient', label: 'Supporting ingredient', label_zh: '辅助成分', parent_id: 'Skincare_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Hydrating_agent', label: 'Hydrating agent', label_zh: '保湿剂', parent_id: 'Supporting_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Barrier_lipid', label: 'Barrier lipid', label_zh: '屏障修护脂质', parent_id: 'Supporting_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Soothing_agent', label: 'Soothing agent', label_zh: '舒缓成分', parent_id: 'Supporting_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'UV_filter', label: 'UV filter', label_zh: '防晒剂', parent_id: 'Skincare_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Mineral_UV_filter', label: 'Mineral UV filter', label_zh: '物理防晒剂', parent_id: 'UV_filter', no_stack: null, stack_reason: null},
  {class_id: 'Chemical_UV_filter', label: 'Chemical UV filter', label_zh: '化学防晒剂', parent_id: 'UV_filter', no_stack: null, stack_reason: null},
  {class_id: 'Potential_irritant', label: 'Potential irritant', label_zh: '潜在刺激物', parent_id: 'Skincare_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Fragrance', label: 'Fragrance', label_zh: '香精', parent_id: 'Potential_irritant', no_stack: null, stack_reason: null},
  {class_id: 'Drying_alcohol', label: 'Drying alcohol', label_zh: '挥发性酒精', parent_id: 'Potential_irritant', no_stack: null, stack_reason: null},
  {class_id: 'Menthol_cooling', label: 'Cooling agent (menthol)', label_zh: '薄荷醇类清凉剂', parent_id: 'Potential_irritant', no_stack: null, stack_reason: null}
] AS r
MERGE (c:IngredientClass {id: trim(r.class_id)})
ON CREATE SET c.label = r.label, c.label_zh = r.label_zh, c.type = trim(r.class_id),
              c.no_stack = coalesce(toBoolean(r.no_stack), false), c.stack_reason = r.stack_reason;

UNWIND [
  {class_id: 'Skincare_ingredient', label: 'Skincare ingredient', label_zh: '护肤成分', parent_id: null, no_stack: null, stack_reason: null},
  {class_id: 'Active_ingredient', label: 'Active ingredient', label_zh: '活性成分', parent_id: 'Skincare_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Retinoid', label: 'Retinoid', label_zh: '维A类', parent_id: 'Active_ingredient', no_stack: 'true', stack_reason: 'Use only one retinoid product per routine slot; layering retinoids raises irritation without clear extra benefit.'},
  {class_id: 'Retinol_family', label: 'Retinol family', label_zh: '视黄醇类（化妆品级）', parent_id: 'Retinoid', no_stack: null, stack_reason: null},
  {class_id: 'Retinoic_acid', label: 'Retinoic acid', label_zh: '维A酸（处方级）', parent_id: 'Retinoid', no_stack: null, stack_reason: null},
  {class_id: 'Synthetic_retinoid', label: 'Synthetic retinoid', label_zh: '合成维A类（阿达帕林）', parent_id: 'Retinoid', no_stack: null, stack_reason: null},
  {class_id: 'Exfoliating_acid', label: 'Exfoliating acid', label_zh: '去角质酸', parent_id: 'Active_ingredient', no_stack: 'true', stack_reason: 'Use only one exfoliating acid product per routine slot to avoid over-exfoliation.'},
  {class_id: 'AHA', label: 'Alpha hydroxy acid (AHA)', label_zh: '果酸 AHA', parent_id: 'Exfoliating_acid', no_stack: null, stack_reason: null},
  {class_id: 'BHA', label: 'Beta hydroxy acid (BHA)', label_zh: '水杨酸 BHA', parent_id: 'Exfoliating_acid', no_stack: null, stack_reason: null},
  {class_id: 'PHA', label: 'Polyhydroxy acid (PHA)', label_zh: '多羟基酸 PHA', parent_id: 'Exfoliating_acid', no_stack: null, stack_reason: null},
  {class_id: 'Vitamin_C', label: 'Vitamin C', label_zh: '维C类', parent_id: 'Active_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'L_ascorbic_acid', label: 'L-ascorbic acid (pure vitamin C)', label_zh: '纯维C（左旋维C）', parent_id: 'Vitamin_C', no_stack: null, stack_reason: null},
  {class_id: 'Vitamin_C_derivative', label: 'Vitamin C derivative', label_zh: '维C衍生物', parent_id: 'Vitamin_C', no_stack: null, stack_reason: null},
  {class_id: 'Benzoyl_peroxide', label: 'Benzoyl peroxide', label_zh: '过氧化苯甲酰', parent_id: 'Active_ingredient', no_stack: 'true', stack_reason: 'Use only one benzoyl peroxide product per routine slot.'},
  {class_id: 'Niacinamide', label: 'Niacinamide', label_zh: '烟酰胺', parent_id: 'Active_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Azelaic_acid', label: 'Azelaic acid', label_zh: '壬二酸', parent_id: 'Active_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Peptide', label: 'Peptide', label_zh: '多肽', parent_id: 'Active_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Retinol_alternative', label: 'Retinol alternative (plant-based)', label_zh: '植物类A醇替代成分', parent_id: 'Active_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Supporting_ingredient', label: 'Supporting ingredient', label_zh: '辅助成分', parent_id: 'Skincare_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Hydrating_agent', label: 'Hydrating agent', label_zh: '保湿剂', parent_id: 'Supporting_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Barrier_lipid', label: 'Barrier lipid', label_zh: '屏障修护脂质', parent_id: 'Supporting_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Soothing_agent', label: 'Soothing agent', label_zh: '舒缓成分', parent_id: 'Supporting_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'UV_filter', label: 'UV filter', label_zh: '防晒剂', parent_id: 'Skincare_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Mineral_UV_filter', label: 'Mineral UV filter', label_zh: '物理防晒剂', parent_id: 'UV_filter', no_stack: null, stack_reason: null},
  {class_id: 'Chemical_UV_filter', label: 'Chemical UV filter', label_zh: '化学防晒剂', parent_id: 'UV_filter', no_stack: null, stack_reason: null},
  {class_id: 'Potential_irritant', label: 'Potential irritant', label_zh: '潜在刺激物', parent_id: 'Skincare_ingredient', no_stack: null, stack_reason: null},
  {class_id: 'Fragrance', label: 'Fragrance', label_zh: '香精', parent_id: 'Potential_irritant', no_stack: null, stack_reason: null},
  {class_id: 'Drying_alcohol', label: 'Drying alcohol', label_zh: '挥发性酒精', parent_id: 'Potential_irritant', no_stack: null, stack_reason: null},
  {class_id: 'Menthol_cooling', label: 'Cooling agent (menthol)', label_zh: '薄荷醇类清凉剂', parent_id: 'Potential_irritant', no_stack: null, stack_reason: null}
] AS r
WITH r WHERE r.parent_id IS NOT NULL AND trim(r.parent_id) <> ''
MATCH (c:IngredientClass {id: trim(r.class_id)}), (p:IngredientClass {id: trim(r.parent_id)})
MERGE (c)-[:SUBCLASS_OF {type: 'subClassOf'}]->(p);

// ---------- 2. Ingredients (instances) -> IS_A -> class ----------
UNWIND [
  {ingredient_id: 'retinol', label: 'Retinol', label_zh: '视黄醇', class_id: 'Retinol_family', aliases: 'Vitamin A'},
  {ingredient_id: 'retinal', label: 'Retinal', label_zh: '视黄醛', class_id: 'Retinol_family', aliases: 'Retinaldehyde'},
  {ingredient_id: 'retinyl_palmitate', label: 'Retinyl Palmitate', label_zh: '视黄醇棕榈酸酯', class_id: 'Retinol_family', aliases: null},
  {ingredient_id: 'hpr', label: 'Hydroxypinacolone Retinoate', label_zh: '羟基频哪酮视黄酸酯', class_id: 'Retinol_family', aliases: 'HPR|Granactive Retinoid'},
  {ingredient_id: 'tretinoin', label: 'Tretinoin', label_zh: '维A酸', class_id: 'Retinoic_acid', aliases: 'Retinoic Acid|Retin-A'},
  {ingredient_id: 'adapalene', label: 'Adapalene', label_zh: '阿达帕林', class_id: 'Synthetic_retinoid', aliases: 'Differin'},
  {ingredient_id: 'glycolic_acid', label: 'Glycolic Acid', label_zh: '甘醇酸', class_id: 'AHA', aliases: null},
  {ingredient_id: 'lactic_acid', label: 'Lactic Acid', label_zh: '乳酸', class_id: 'AHA', aliases: null},
  {ingredient_id: 'mandelic_acid', label: 'Mandelic Acid', label_zh: '杏仁酸', class_id: 'AHA', aliases: null},
  {ingredient_id: 'salicylic_acid', label: 'Salicylic Acid', label_zh: '水杨酸', class_id: 'BHA', aliases: 'BHA'},
  {ingredient_id: 'gluconolactone', label: 'Gluconolactone', label_zh: '葡糖酸内酯', class_id: 'PHA', aliases: 'PHA'},
  {ingredient_id: 'lactobionic_acid', label: 'Lactobionic Acid', label_zh: '乳糖酸', class_id: 'PHA', aliases: null},
  {ingredient_id: 'ascorbic_acid', label: 'Ascorbic Acid', label_zh: '抗坏血酸（左旋维C）', class_id: 'L_ascorbic_acid', aliases: 'L-Ascorbic Acid|Vitamin C|LAA'},
  {ingredient_id: 'sodium_ascorbyl_phosphate', label: 'Sodium Ascorbyl Phosphate', label_zh: '抗坏血酸磷酸酯钠', class_id: 'Vitamin_C_derivative', aliases: 'SAP'},
  {ingredient_id: 'ascorbyl_glucoside', label: 'Ascorbyl Glucoside', label_zh: '抗坏血酸葡糖苷', class_id: 'Vitamin_C_derivative', aliases: 'AA2G'},
  {ingredient_id: 'ethyl_ascorbic_acid', label: '3-O-Ethyl Ascorbic Acid', label_zh: '3-O-乙基抗坏血酸', class_id: 'Vitamin_C_derivative', aliases: 'Ethyl Ascorbic Acid'},
  {ingredient_id: 'tetrahexyldecyl_ascorbate', label: 'Tetrahexyldecyl Ascorbate', label_zh: '四己基癸醇抗坏血酸酯', class_id: 'Vitamin_C_derivative', aliases: 'THD Ascorbate'},
  {ingredient_id: 'benzoyl_peroxide', label: 'Benzoyl Peroxide', label_zh: '过氧化苯甲酰', class_id: 'Benzoyl_peroxide', aliases: 'BPO'},
  {ingredient_id: 'niacinamide', label: 'Niacinamide', label_zh: '烟酰胺', class_id: 'Niacinamide', aliases: 'Nicotinamide|Vitamin B3'},
  {ingredient_id: 'azelaic_acid', label: 'Azelaic Acid', label_zh: '壬二酸', class_id: 'Azelaic_acid', aliases: null},
  {ingredient_id: 'copper_tripeptide_1', label: 'Copper Tripeptide-1', label_zh: '三肽-1铜', class_id: 'Peptide', aliases: 'GHK-Cu|Copper Peptide'},
  {ingredient_id: 'palmitoyl_pentapeptide_4', label: 'Palmitoyl Pentapeptide-4', label_zh: '棕榈酰五肽-4', class_id: 'Peptide', aliases: 'Matrixyl'},
  {ingredient_id: 'sodium_hyaluronate', label: 'Sodium Hyaluronate', label_zh: '透明质酸钠', class_id: 'Hydrating_agent', aliases: 'Hyaluronic Acid|Hydrolyzed Hyaluronic Acid|Sodium Acetylated Hyaluronate'},
  {ingredient_id: 'glycerin', label: 'Glycerin', label_zh: '甘油', class_id: 'Hydrating_agent', aliases: 'Glycerol'},
  {ingredient_id: 'ceramide_np', label: 'Ceramide NP', label_zh: '神经酰胺 NP', class_id: 'Barrier_lipid', aliases: 'Ceramide 3'},
  {ingredient_id: 'panthenol', label: 'Panthenol', label_zh: '泛醇', class_id: 'Soothing_agent', aliases: 'Vitamin B5|Pro-Vitamin B5'},
  {ingredient_id: 'centella_extract', label: 'Centella Asiatica Extract', label_zh: '积雪草提取物', class_id: 'Soothing_agent', aliases: 'Cica|Centella Asiatica Leaf Extract'},
  {ingredient_id: 'allantoin', label: 'Allantoin', label_zh: '尿囊素', class_id: 'Soothing_agent', aliases: null},
  {ingredient_id: 'zinc_oxide', label: 'Zinc Oxide', label_zh: '氧化锌', class_id: 'Mineral_UV_filter', aliases: null},
  {ingredient_id: 'titanium_dioxide', label: 'Titanium Dioxide', label_zh: '二氧化钛', class_id: 'Mineral_UV_filter', aliases: null},
  {ingredient_id: 'octinoxate', label: 'Ethylhexyl Methoxycinnamate', label_zh: '甲氧基肉桂酸乙基己酯', class_id: 'Chemical_UV_filter', aliases: 'Octinoxate'},
  {ingredient_id: 'bemotrizinol', label: 'Bis-Ethylhexyloxyphenol Methoxyphenyl Triazine', label_zh: '双-乙基己氧苯酚甲氧苯基三嗪', class_id: 'Chemical_UV_filter', aliases: 'Tinosorb S|Bemotrizinol'},
  {ingredient_id: 'parfum', label: 'Parfum', label_zh: '香精', class_id: 'Fragrance', aliases: 'Fragrance|Aroma'},
  {ingredient_id: 'alcohol_denat', label: 'Alcohol Denat.', label_zh: '变性乙醇', class_id: 'Drying_alcohol', aliases: 'SD Alcohol|Ethanol'},
  {ingredient_id: 'menthol', label: 'Menthol', label_zh: '薄荷醇', class_id: 'Menthol_cooling', aliases: null},
  {ingredient_id: 'retinyl_propionate', label: 'Retinyl Propionate', label_zh: '视黄醇丙酸酯', class_id: 'Retinol_family', aliases: null},
  {ingredient_id: 'bakuchiol', label: 'Bakuchiol', label_zh: '补骨脂酚', class_id: 'Retinol_alternative', aliases: null},
  {ingredient_id: 'capryloyl_salicylic_acid', label: 'Capryloyl Salicylic Acid', label_zh: '辛酰水杨酸', class_id: 'BHA', aliases: 'LHA'},
  {ingredient_id: 'potassium_azeloyl_diglycinate', label: 'Potassium Azeloyl Diglycinate', label_zh: '壬二酰二甘氨酸钾', class_id: 'Azelaic_acid', aliases: 'Azeloglicina'},
  {ingredient_id: 'ascorbyl_palmitate', label: 'Ascorbyl Palmitate', label_zh: '抗坏血酸棕榈酸酯', class_id: 'Vitamin_C_derivative', aliases: null},
  {ingredient_id: 'palmitoyl_tripeptide_1', label: 'Palmitoyl Tripeptide-1', label_zh: '棕榈酰三肽-1', class_id: 'Peptide', aliases: null},
  {ingredient_id: 'palmitoyl_tetrapeptide_7', label: 'Palmitoyl Tetrapeptide-7', label_zh: '棕榈酰四肽-7', class_id: 'Peptide', aliases: null},
  {ingredient_id: 'ceramide_ap', label: 'Ceramide AP', label_zh: '神经酰胺 AP', class_id: 'Barrier_lipid', aliases: 'Ceramide 6 II'},
  {ingredient_id: 'ceramide_eop', label: 'Ceramide EOP', label_zh: '神经酰胺 EOP', class_id: 'Barrier_lipid', aliases: 'Ceramide 1'},
  {ingredient_id: 'ceramide_ns', label: 'Ceramide NS', label_zh: '神经酰胺 NS', class_id: 'Barrier_lipid', aliases: 'Ceramide 2'},
  {ingredient_id: 'ceramide_as', label: 'Ceramide AS', label_zh: '神经酰胺 AS', class_id: 'Barrier_lipid', aliases: 'Ceramide 5'},
  {ingredient_id: 'pseudo_ceramide', label: 'Hydroxypropyl Bispalmitamide MEA', label_zh: '羟丙基双棕榈酰胺 MEA（类神经酰胺）', class_id: 'Barrier_lipid', aliases: 'Pseudo-ceramide'},
  {ingredient_id: 'madecassoside', label: 'Madecassoside', label_zh: '羟基积雪草苷', class_id: 'Soothing_agent', aliases: 'Centella derivative'},
  {ingredient_id: 'ethylhexyl_triazone', label: 'Ethylhexyl Triazone', label_zh: '乙基己基三嗪酮', class_id: 'Chemical_UV_filter', aliases: 'Uvinul T 150'},
  {ingredient_id: 'dhhb', label: 'Diethylamino Hydroxybenzoyl Hexyl Benzoate', label_zh: '二乙氨羟苯甲酰基苯甲酸己酯', class_id: 'Chemical_UV_filter', aliases: 'Uvinul A Plus|DHHB'},
  {ingredient_id: 'octocrylene', label: 'Octocrylene', label_zh: '奥克立林', class_id: 'Chemical_UV_filter', aliases: null},
  {ingredient_id: 'ethylhexyl_salicylate', label: 'Ethylhexyl Salicylate', label_zh: '水杨酸乙基己酯', class_id: 'Chemical_UV_filter', aliases: 'Octisalate (a UV filter, NOT salicylic acid)'},
  {ingredient_id: 'homosalate', label: 'Homosalate', label_zh: '胡莫柳酯', class_id: 'Chemical_UV_filter', aliases: null},
  {ingredient_id: 'bisoctrizole', label: 'Methylene Bis-Benzotriazolyl Tetramethylbutylphenol', label_zh: '亚甲基双-苯并三唑基四甲基丁基酚', class_id: 'Chemical_UV_filter', aliases: 'Tinosorb M|Bisoctrizole'},
  {ingredient_id: 'alcohol', label: 'Alcohol', label_zh: '乙醇', class_id: 'Drying_alcohol', aliases: 'Ethanol'},
  {ingredient_id: 'linalool', label: 'Linalool', label_zh: '芳樟醇', class_id: 'Fragrance', aliases: 'Fragrance allergen'},
  {ingredient_id: 'limonene', label: 'Limonene', label_zh: '柠檬烯', class_id: 'Fragrance', aliases: 'Fragrance allergen'},
  {ingredient_id: 'menthyl_lactate', label: 'Menthyl Lactate', label_zh: '乳酸薄荷酯', class_id: 'Menthol_cooling', aliases: null},
  {ingredient_id: 'menthoxypropanediol', label: 'Menthoxypropanediol', label_zh: '薄荷氧基丙二醇', class_id: 'Menthol_cooling', aliases: 'Cooling agent'},
  {ingredient_id: 'peppermint_extract', label: 'Mentha Piperita (Peppermint) Leaf Extract', label_zh: '薄荷叶提取物', class_id: 'Menthol_cooling', aliases: 'Peppermint'}
] AS r
MATCH (c:IngredientClass {id: trim(r.class_id)})
MERGE (i:Ingredient {id: trim(r.ingredient_id)})
ON CREATE SET i.label = r.label, i.label_zh = r.label_zh, i.type = trim(r.class_id),
              i.aliases = CASE WHEN r.aliases IS NULL THEN [] ELSE split(r.aliases, '|') END
MERGE (i)-[:IS_A {type: 'type'}]->(c);

// ---------- 3. Concerns and skin types ----------
UNWIND [
  {concern_id: 'acne', label: 'Acne', label_zh: '痘痘'},
  {concern_id: 'hyperpigmentation', label: 'Hyperpigmentation', label_zh: '色沉/痘印'},
  {concern_id: 'signs_of_aging', label: 'Signs of aging', label_zh: '细纹/抗老'},
  {concern_id: 'uneven_texture', label: 'Uneven texture', label_zh: '粗糙/闭口'},
  {concern_id: 'dehydration', label: 'Dehydration', label_zh: '缺水'},
  {concern_id: 'barrier_damage', label: 'Barrier damage', label_zh: '屏障受损'},
  {concern_id: 'redness', label: 'Redness', label_zh: '泛红'},
  {concern_id: 'sun_damage', label: 'Sun damage', label_zh: '光老化/晒伤'},
  {concern_id: 'oiliness', label: 'Oiliness', label_zh: '出油'}
] AS r
MERGE (n:Concern {id: trim(r.concern_id)})
ON CREATE SET n.label = r.label, n.label_zh = r.label_zh, n.type = 'Skin_concern';

UNWIND [
  {skin_type_id: 'oily', label: 'Oily', label_zh: '油皮'},
  {skin_type_id: 'dry', label: 'Dry', label_zh: '干皮'},
  {skin_type_id: 'combination', label: 'Combination', label_zh: '混合皮'},
  {skin_type_id: 'normal', label: 'Normal', label_zh: '中性皮'},
  {skin_type_id: 'sensitive', label: 'Sensitive', label_zh: '敏感肌'}
] AS r
MERGE (n:SkinType {id: trim(r.skin_type_id)})
ON CREATE SET n.label = r.label, n.label_zh = r.label_zh, n.type = 'Skin_type';

// ---------- 4. Class-level knowledge (rules) ----------
UNWIND [
  {class_id: 'Retinoid', concern_id: 'acne'},
  {class_id: 'Retinoid', concern_id: 'signs_of_aging'},
  {class_id: 'Retinoid', concern_id: 'uneven_texture'},
  {class_id: 'Retinoid', concern_id: 'hyperpigmentation'},
  {class_id: 'Exfoliating_acid', concern_id: 'uneven_texture'},
  {class_id: 'AHA', concern_id: 'hyperpigmentation'},
  {class_id: 'BHA', concern_id: 'acne'},
  {class_id: 'BHA', concern_id: 'oiliness'},
  {class_id: 'Vitamin_C', concern_id: 'hyperpigmentation'},
  {class_id: 'Vitamin_C', concern_id: 'signs_of_aging'},
  {class_id: 'Benzoyl_peroxide', concern_id: 'acne'},
  {class_id: 'Niacinamide', concern_id: 'oiliness'},
  {class_id: 'Niacinamide', concern_id: 'hyperpigmentation'},
  {class_id: 'Niacinamide', concern_id: 'barrier_damage'},
  {class_id: 'Azelaic_acid', concern_id: 'acne'},
  {class_id: 'Azelaic_acid', concern_id: 'hyperpigmentation'},
  {class_id: 'Azelaic_acid', concern_id: 'redness'},
  {class_id: 'Peptide', concern_id: 'signs_of_aging'},
  {class_id: 'Retinol_alternative', concern_id: 'signs_of_aging'},
  {class_id: 'Hydrating_agent', concern_id: 'dehydration'},
  {class_id: 'Barrier_lipid', concern_id: 'barrier_damage'},
  {class_id: 'Barrier_lipid', concern_id: 'dehydration'},
  {class_id: 'Soothing_agent', concern_id: 'redness'},
  {class_id: 'Soothing_agent', concern_id: 'barrier_damage'},
  {class_id: 'UV_filter', concern_id: 'sun_damage'}
] AS r
MATCH (c:IngredientClass {id: trim(r.class_id)}), (k:Concern {id: trim(r.concern_id)})
MERGE (c)-[:TARGETS {type: 'targets'}]->(k);

UNWIND [
  {rule_id: 'R01', class_a: 'Retinoid', class_b: 'Exfoliating_acid', rel_type: 'CONFLICTS_WITH', severity: 'Medium', severity_rank: '2', evidence: 'Moderate', reason: 'Both speed up skin turnover; using them together increases redness, peeling and stinging. The tretinoin label advises particular caution with salicylic acid and other drying products.', advice: 'Use them in different routine slots (e.g. acid in the morning, retinoid at night) or on alternate nights.', source: 'RETIN-A (tretinoin) prescribing information, Precautions', source_url: 'https://www.drugs.com/pro/retin-a-cream-gel-liquid.html'},
  {rule_id: 'R02', class_a: 'Retinoid', class_b: 'Benzoyl_peroxide', rel_type: 'CONFLICTS_WITH', severity: 'Medium', severity_rank: '2', evidence: 'Moderate', reason: 'Using two topical acne actives at the same time makes irritation and dryness more likely.', advice: 'Apply benzoyl peroxide in the morning and the retinoid at night, or alternate days.', source: 'US FDA, 21 CFR 333.350 Labeling of topical acne drug products | RETIN-A (tretinoin) prescribing information, Precautions', source_url: 'https://www.law.cornell.edu/cfr/text/21/333.350 | https://www.drugs.com/pro/retin-a-cream-gel-liquid.html'},
  {rule_id: 'R03', class_a: 'Retinoic_acid', class_b: 'Benzoyl_peroxide', rel_type: 'CONFLICTS_WITH', severity: 'High', severity_rank: '3', evidence: 'Strong', reason: 'Benzoyl peroxide and light degrade tretinoin: in a lab study more than 50% was lost within about 2 hours. Adapalene was not affected.', advice: 'Never layer them. Use benzoyl peroxide in the morning and tretinoin at night, or ask a pharmacist about adapalene.', source: 'Martin B. et al. (1998). Chemical stability of adapalene and tretinoin when combined with benzoyl peroxide. Br J Dermatol 139 Suppl 52:8-11 | Baumann L.S. (2014). Cosmeceutical critique: Benzoyl peroxide. MDedge Dermatology', source_url: 'https://pubmed.ncbi.nlm.nih.gov/9990414/ | https://www.mdedge.com/dermatology/article/82396/aesthetic-dermatology/cosmeceutical-critique-benzoyl-peroxide/page/0/1'},
  {rule_id: 'R04', class_a: 'Retinoid', class_b: 'Drying_alcohol', rel_type: 'CONFLICTS_WITH', severity: 'Low', severity_rank: '1', evidence: 'Moderate', reason: 'Products with high concentrations of alcohol or astringents add to retinoid irritation.', advice: 'Choose an alcohol-free toner for nights when you use a retinoid.', source: 'RETIN-A (tretinoin) prescribing information, Precautions', source_url: 'https://www.drugs.com/pro/retin-a-cream-gel-liquid.html'},
  {rule_id: 'R05', class_a: 'Benzoyl_peroxide', class_b: 'BHA', rel_type: 'CONFLICTS_WITH', severity: 'Medium', severity_rank: '2', evidence: 'Moderate', reason: 'Both are topical acne actives; using them at the same time makes irritation and dryness more likely.', advice: 'Use one in the morning and the other at night; if irritation occurs, use only one.', source: 'US FDA, 21 CFR 333.350 Labeling of topical acne drug products', source_url: 'https://www.law.cornell.edu/cfr/text/21/333.350'},
  {rule_id: 'R06', class_a: 'Benzoyl_peroxide', class_b: 'L_ascorbic_acid', rel_type: 'CONFLICTS_WITH', severity: 'Low', severity_rank: '1', evidence: 'Theoretical', reason: 'Benzoyl peroxide is a strong oxidiser and may oxidise pure vitamin C, reducing its benefit.', advice: 'Use vitamin C in the morning and benzoyl peroxide at night.', source: 'Baumann L.S. (2014). Cosmeceutical critique: Benzoyl peroxide. MDedge Dermatology', source_url: 'https://www.mdedge.com/dermatology/article/82396/aesthetic-dermatology/cosmeceutical-critique-benzoyl-peroxide/page/0/1'},
  {rule_id: 'C01', class_a: 'Niacinamide', class_b: 'L_ascorbic_acid', rel_type: 'COMPATIBLE_WITH', severity: 'None', severity_rank: '0', evidence: 'Myth debunked', reason: 'The idea that these two cancel each other out comes from 1960s studies with unstabilised ingredients kept at high heat; modern formulas can be layered safely.', advice: 'Safe to use together in the same routine.', source: 'Paula\'s Choice Research Team. Can niacinamide and vitamin C be used together? (cites Molecules, 2022) | Levin J., Momin S.B. (2010). How much do we really know about our favorite cosmeceutical ingredients? J Clin Aesthet Dermatol 3(2):22-41', source_url: 'https://www.paulaschoice.com.au/blogs/expert-skincare-advice/can-niacinamide-and-vitamin-c-be-used-together | https://pmc.ncbi.nlm.nih.gov/articles/PMC2921764'},
  {rule_id: 'C02', class_a: 'Exfoliating_acid', class_b: 'L_ascorbic_acid', rel_type: 'COMPATIBLE_WITH', severity: 'None', severity_rank: '0', evidence: 'Expert opinion', reason: 'Pure vitamin C is absorbed best at low pH; a low-pH acid cleanser before it can help absorption.', advice: 'If your skin tolerates it, use the acid cleanser first, then vitamin C.', source: 'Baumann L.S. (2018). Skin care product layering affects efficacy and outcomes of regimens. MDedge Dermatology', source_url: 'https://www.mdedge.com/dermatology/article/163286/aesthetic-dermatology/skin-care-product-layering-affects-efficacy-and/page/0/2'},
  {rule_id: 'C03', class_a: 'Retinoid', class_b: 'Barrier_lipid', rel_type: 'COMPATIBLE_WITH', severity: 'None', severity_rank: '0', evidence: 'Expert opinion', reason: 'Applying a retinoid on top of a moisturiser can reduce side effects for first-time users.', advice: 'Apply moisturiser first, then the retinoid.', source: 'Baumann L.S. (2018). Skin care product layering affects efficacy and outcomes of regimens. MDedge Dermatology', source_url: 'https://www.mdedge.com/dermatology/article/163286/aesthetic-dermatology/skin-care-product-layering-affects-efficacy-and/page/0/2'}
] AS r
WITH r WHERE r.rel_type = 'CONFLICTS_WITH'
MATCH (a:IngredientClass {id: trim(r.class_a)}), (b:IngredientClass {id: trim(r.class_b)})
MERGE (a)-[x:CONFLICTS_WITH {rule_id: r.rule_id}]->(b)
ON CREATE SET x.type = 'conflictsWith', x.severity = r.severity, x.severity_rank = toInteger(r.severity_rank),
              x.evidence = r.evidence, x.reason = r.reason, x.advice = r.advice,
              x.source = r.source, x.source_url = r.source_url;

UNWIND [
  {rule_id: 'R01', class_a: 'Retinoid', class_b: 'Exfoliating_acid', rel_type: 'CONFLICTS_WITH', severity: 'Medium', severity_rank: '2', evidence: 'Moderate', reason: 'Both speed up skin turnover; using them together increases redness, peeling and stinging. The tretinoin label advises particular caution with salicylic acid and other drying products.', advice: 'Use them in different routine slots (e.g. acid in the morning, retinoid at night) or on alternate nights.', source: 'RETIN-A (tretinoin) prescribing information, Precautions', source_url: 'https://www.drugs.com/pro/retin-a-cream-gel-liquid.html'},
  {rule_id: 'R02', class_a: 'Retinoid', class_b: 'Benzoyl_peroxide', rel_type: 'CONFLICTS_WITH', severity: 'Medium', severity_rank: '2', evidence: 'Moderate', reason: 'Using two topical acne actives at the same time makes irritation and dryness more likely.', advice: 'Apply benzoyl peroxide in the morning and the retinoid at night, or alternate days.', source: 'US FDA, 21 CFR 333.350 Labeling of topical acne drug products | RETIN-A (tretinoin) prescribing information, Precautions', source_url: 'https://www.law.cornell.edu/cfr/text/21/333.350 | https://www.drugs.com/pro/retin-a-cream-gel-liquid.html'},
  {rule_id: 'R03', class_a: 'Retinoic_acid', class_b: 'Benzoyl_peroxide', rel_type: 'CONFLICTS_WITH', severity: 'High', severity_rank: '3', evidence: 'Strong', reason: 'Benzoyl peroxide and light degrade tretinoin: in a lab study more than 50% was lost within about 2 hours. Adapalene was not affected.', advice: 'Never layer them. Use benzoyl peroxide in the morning and tretinoin at night, or ask a pharmacist about adapalene.', source: 'Martin B. et al. (1998). Chemical stability of adapalene and tretinoin when combined with benzoyl peroxide. Br J Dermatol 139 Suppl 52:8-11 | Baumann L.S. (2014). Cosmeceutical critique: Benzoyl peroxide. MDedge Dermatology', source_url: 'https://pubmed.ncbi.nlm.nih.gov/9990414/ | https://www.mdedge.com/dermatology/article/82396/aesthetic-dermatology/cosmeceutical-critique-benzoyl-peroxide/page/0/1'},
  {rule_id: 'R04', class_a: 'Retinoid', class_b: 'Drying_alcohol', rel_type: 'CONFLICTS_WITH', severity: 'Low', severity_rank: '1', evidence: 'Moderate', reason: 'Products with high concentrations of alcohol or astringents add to retinoid irritation.', advice: 'Choose an alcohol-free toner for nights when you use a retinoid.', source: 'RETIN-A (tretinoin) prescribing information, Precautions', source_url: 'https://www.drugs.com/pro/retin-a-cream-gel-liquid.html'},
  {rule_id: 'R05', class_a: 'Benzoyl_peroxide', class_b: 'BHA', rel_type: 'CONFLICTS_WITH', severity: 'Medium', severity_rank: '2', evidence: 'Moderate', reason: 'Both are topical acne actives; using them at the same time makes irritation and dryness more likely.', advice: 'Use one in the morning and the other at night; if irritation occurs, use only one.', source: 'US FDA, 21 CFR 333.350 Labeling of topical acne drug products', source_url: 'https://www.law.cornell.edu/cfr/text/21/333.350'},
  {rule_id: 'R06', class_a: 'Benzoyl_peroxide', class_b: 'L_ascorbic_acid', rel_type: 'CONFLICTS_WITH', severity: 'Low', severity_rank: '1', evidence: 'Theoretical', reason: 'Benzoyl peroxide is a strong oxidiser and may oxidise pure vitamin C, reducing its benefit.', advice: 'Use vitamin C in the morning and benzoyl peroxide at night.', source: 'Baumann L.S. (2014). Cosmeceutical critique: Benzoyl peroxide. MDedge Dermatology', source_url: 'https://www.mdedge.com/dermatology/article/82396/aesthetic-dermatology/cosmeceutical-critique-benzoyl-peroxide/page/0/1'},
  {rule_id: 'C01', class_a: 'Niacinamide', class_b: 'L_ascorbic_acid', rel_type: 'COMPATIBLE_WITH', severity: 'None', severity_rank: '0', evidence: 'Myth debunked', reason: 'The idea that these two cancel each other out comes from 1960s studies with unstabilised ingredients kept at high heat; modern formulas can be layered safely.', advice: 'Safe to use together in the same routine.', source: 'Paula\'s Choice Research Team. Can niacinamide and vitamin C be used together? (cites Molecules, 2022) | Levin J., Momin S.B. (2010). How much do we really know about our favorite cosmeceutical ingredients? J Clin Aesthet Dermatol 3(2):22-41', source_url: 'https://www.paulaschoice.com.au/blogs/expert-skincare-advice/can-niacinamide-and-vitamin-c-be-used-together | https://pmc.ncbi.nlm.nih.gov/articles/PMC2921764'},
  {rule_id: 'C02', class_a: 'Exfoliating_acid', class_b: 'L_ascorbic_acid', rel_type: 'COMPATIBLE_WITH', severity: 'None', severity_rank: '0', evidence: 'Expert opinion', reason: 'Pure vitamin C is absorbed best at low pH; a low-pH acid cleanser before it can help absorption.', advice: 'If your skin tolerates it, use the acid cleanser first, then vitamin C.', source: 'Baumann L.S. (2018). Skin care product layering affects efficacy and outcomes of regimens. MDedge Dermatology', source_url: 'https://www.mdedge.com/dermatology/article/163286/aesthetic-dermatology/skin-care-product-layering-affects-efficacy-and/page/0/2'},
  {rule_id: 'C03', class_a: 'Retinoid', class_b: 'Barrier_lipid', rel_type: 'COMPATIBLE_WITH', severity: 'None', severity_rank: '0', evidence: 'Expert opinion', reason: 'Applying a retinoid on top of a moisturiser can reduce side effects for first-time users.', advice: 'Apply moisturiser first, then the retinoid.', source: 'Baumann L.S. (2018). Skin care product layering affects efficacy and outcomes of regimens. MDedge Dermatology', source_url: 'https://www.mdedge.com/dermatology/article/163286/aesthetic-dermatology/skin-care-product-layering-affects-efficacy-and/page/0/2'}
] AS r
WITH r WHERE r.rel_type = 'COMPATIBLE_WITH'
MATCH (a:IngredientClass {id: trim(r.class_a)}), (b:IngredientClass {id: trim(r.class_b)})
MERGE (a)-[x:COMPATIBLE_WITH {rule_id: r.rule_id}]->(b)
ON CREATE SET x.type = 'compatibleWith', x.evidence = r.evidence, x.reason = r.reason, x.advice = r.advice,
              x.source = r.source, x.source_url = r.source_url;

UNWIND [
  {class_id: 'Retinoid', required_class: 'UV_filter', reason: 'Retinoids increase sun sensitivity; use them at night and wear sunscreen during the day.', advice: 'Add a broad-spectrum SPF 30+ sunscreen as the last step of your morning routine.', source: 'American Academy of Dermatology. Retinoid or retinol? | RETIN-A (tretinoin) prescribing information, Precautions', source_url: 'https://aad.org/public/everyday-care/skin-care-secrets/anti-aging/retinoid-retinol | https://www.drugs.com/pro/retin-a-cream-gel-liquid.html'},
  {class_id: 'AHA', required_class: 'UV_filter', reason: 'AHAs can increase sensitivity to the sun; FDA requires a \'Sunburn Alert\' and advises sunscreen during use and for a week afterwards.', advice: 'Add a broad-spectrum SPF 30+ sunscreen as the last step of your morning routine.', source: 'US FDA. Alpha Hydroxy Acids (cosmetics ingredient page, Sunburn Alert)', source_url: 'https://www.fda.gov/cosmetics/ingredients/alpha-hydroxy-acids'},
  {class_id: 'Benzoyl_peroxide', required_class: 'UV_filter', reason: 'Labelling for benzoyl peroxide advises avoiding unnecessary sun exposure and using a sunscreen.', advice: 'Add a broad-spectrum SPF 30+ sunscreen as the last step of your morning routine.', source: 'US FDA, 21 CFR 333.350 Labeling of topical acne drug products', source_url: 'https://www.law.cornell.edu/cfr/text/21/333.350'}
] AS r
MATCH (a:IngredientClass {id: trim(r.class_id)}), (b:IngredientClass {id: trim(r.required_class)})
MERGE (a)-[x:REQUIRES]->(b)
ON CREATE SET x.type = 'requiresSunProtection', x.reason = r.reason, x.advice = r.advice,
              x.source = r.source, x.source_url = r.source_url;

UNWIND [
  {class_id: 'Retinoid', skin_type_id: 'sensitive', rel_type: 'CAUTION_FOR', reason: 'People with skin allergies, dryness, or a lot of redness are probably not good candidates for retinoids.', advice: 'Start with the mildest formula every other night, or skip retinoids if skin is inflamed.', source: 'American Academy of Dermatology. Retinoid or retinol?', source_url: 'https://aad.org/public/everyday-care/skin-care-secrets/anti-aging/retinoid-retinol'},
  {class_id: 'Retinoid', skin_type_id: 'dry', rel_type: 'CAUTION_FOR', reason: 'Retinoids can worsen dryness.', advice: 'Start slowly and use a moisturiser.', source: 'American Academy of Dermatology. Retinoid or retinol?', source_url: 'https://aad.org/public/everyday-care/skin-care-secrets/anti-aging/retinoid-retinol'},
  {class_id: 'AHA', skin_type_id: 'sensitive', rel_type: 'CAUTION_FOR', reason: 'Glycolic and lactic acid are on the AAD list of ingredients for rosacea-prone skin to avoid.', advice: 'Prefer a gentler option (e.g. PHA or azelaic acid) or stop exfoliating.', source: 'American Academy of Dermatology. 6 rosacea skin care tips dermatologists give their patients', source_url: 'https://www.aad.org/public/diseases/acne-and-rosacea/rosacea/6-rosacea-skin-care-tips-dermatologists-give-their-patients'},
  {class_id: 'Benzoyl_peroxide', skin_type_id: 'sensitive', rel_type: 'CAUTION_FOR', reason: 'Benzoyl peroxide labelling says not to use it if you have very sensitive skin.', advice: 'Patch test first or choose a gentler acne active.', source: 'US FDA, 21 CFR 333.350 Labeling of topical acne drug products', source_url: 'https://www.law.cornell.edu/cfr/text/21/333.350'},
  {class_id: 'Fragrance', skin_type_id: 'sensitive', rel_type: 'CAUTION_FOR', reason: 'Dermatologists advise sensitive (rosacea-prone) skin to choose fragrance-free products.', advice: 'Look for \'fragrance-free\' rather than \'unscented\'.', source: 'American Academy of Dermatology. 6 rosacea skin care tips dermatologists give their patients', source_url: 'https://www.aad.org/public/diseases/acne-and-rosacea/rosacea/6-rosacea-skin-care-tips-dermatologists-give-their-patients'},
  {class_id: 'Drying_alcohol', skin_type_id: 'sensitive', rel_type: 'CAUTION_FOR', reason: 'Alcohol is on the AAD list of ingredients for rosacea-prone skin to avoid.', advice: 'Choose alcohol-free products.', source: 'American Academy of Dermatology. 6 rosacea skin care tips dermatologists give their patients', source_url: 'https://www.aad.org/public/diseases/acne-and-rosacea/rosacea/6-rosacea-skin-care-tips-dermatologists-give-their-patients'},
  {class_id: 'Menthol_cooling', skin_type_id: 'sensitive', rel_type: 'CAUTION_FOR', reason: 'Menthol is on the AAD list of ingredients for rosacea-prone skin to avoid.', advice: 'Choose products without menthol.', source: 'American Academy of Dermatology. 6 rosacea skin care tips dermatologists give their patients', source_url: 'https://www.aad.org/public/diseases/acne-and-rosacea/rosacea/6-rosacea-skin-care-tips-dermatologists-give-their-patients'},
  {class_id: 'Mineral_UV_filter', skin_type_id: 'sensitive', rel_type: 'RECOMMENDED_FOR', reason: 'If sunscreen irritates the skin, dermatologists suggest zinc oxide and/or titanium dioxide (mineral sunscreen).', advice: 'Prefer a fragrance-free mineral sunscreen.', source: 'American Academy of Dermatology. 6 rosacea skin care tips dermatologists give their patients', source_url: 'https://www.aad.org/public/diseases/acne-and-rosacea/rosacea/6-rosacea-skin-care-tips-dermatologists-give-their-patients'}
] AS r
WITH r WHERE r.rel_type = 'CAUTION_FOR'
MATCH (a:IngredientClass {id: trim(r.class_id)}), (s:SkinType {id: trim(r.skin_type_id)})
MERGE (a)-[x:CAUTION_FOR]->(s)
ON CREATE SET x.type = 'cautionFor', x.reason = r.reason, x.advice = r.advice,
              x.source = r.source, x.source_url = r.source_url;

UNWIND [
  {class_id: 'Retinoid', skin_type_id: 'sensitive', rel_type: 'CAUTION_FOR', reason: 'People with skin allergies, dryness, or a lot of redness are probably not good candidates for retinoids.', advice: 'Start with the mildest formula every other night, or skip retinoids if skin is inflamed.', source: 'American Academy of Dermatology. Retinoid or retinol?', source_url: 'https://aad.org/public/everyday-care/skin-care-secrets/anti-aging/retinoid-retinol'},
  {class_id: 'Retinoid', skin_type_id: 'dry', rel_type: 'CAUTION_FOR', reason: 'Retinoids can worsen dryness.', advice: 'Start slowly and use a moisturiser.', source: 'American Academy of Dermatology. Retinoid or retinol?', source_url: 'https://aad.org/public/everyday-care/skin-care-secrets/anti-aging/retinoid-retinol'},
  {class_id: 'AHA', skin_type_id: 'sensitive', rel_type: 'CAUTION_FOR', reason: 'Glycolic and lactic acid are on the AAD list of ingredients for rosacea-prone skin to avoid.', advice: 'Prefer a gentler option (e.g. PHA or azelaic acid) or stop exfoliating.', source: 'American Academy of Dermatology. 6 rosacea skin care tips dermatologists give their patients', source_url: 'https://www.aad.org/public/diseases/acne-and-rosacea/rosacea/6-rosacea-skin-care-tips-dermatologists-give-their-patients'},
  {class_id: 'Benzoyl_peroxide', skin_type_id: 'sensitive', rel_type: 'CAUTION_FOR', reason: 'Benzoyl peroxide labelling says not to use it if you have very sensitive skin.', advice: 'Patch test first or choose a gentler acne active.', source: 'US FDA, 21 CFR 333.350 Labeling of topical acne drug products', source_url: 'https://www.law.cornell.edu/cfr/text/21/333.350'},
  {class_id: 'Fragrance', skin_type_id: 'sensitive', rel_type: 'CAUTION_FOR', reason: 'Dermatologists advise sensitive (rosacea-prone) skin to choose fragrance-free products.', advice: 'Look for \'fragrance-free\' rather than \'unscented\'.', source: 'American Academy of Dermatology. 6 rosacea skin care tips dermatologists give their patients', source_url: 'https://www.aad.org/public/diseases/acne-and-rosacea/rosacea/6-rosacea-skin-care-tips-dermatologists-give-their-patients'},
  {class_id: 'Drying_alcohol', skin_type_id: 'sensitive', rel_type: 'CAUTION_FOR', reason: 'Alcohol is on the AAD list of ingredients for rosacea-prone skin to avoid.', advice: 'Choose alcohol-free products.', source: 'American Academy of Dermatology. 6 rosacea skin care tips dermatologists give their patients', source_url: 'https://www.aad.org/public/diseases/acne-and-rosacea/rosacea/6-rosacea-skin-care-tips-dermatologists-give-their-patients'},
  {class_id: 'Menthol_cooling', skin_type_id: 'sensitive', rel_type: 'CAUTION_FOR', reason: 'Menthol is on the AAD list of ingredients for rosacea-prone skin to avoid.', advice: 'Choose products without menthol.', source: 'American Academy of Dermatology. 6 rosacea skin care tips dermatologists give their patients', source_url: 'https://www.aad.org/public/diseases/acne-and-rosacea/rosacea/6-rosacea-skin-care-tips-dermatologists-give-their-patients'},
  {class_id: 'Mineral_UV_filter', skin_type_id: 'sensitive', rel_type: 'RECOMMENDED_FOR', reason: 'If sunscreen irritates the skin, dermatologists suggest zinc oxide and/or titanium dioxide (mineral sunscreen).', advice: 'Prefer a fragrance-free mineral sunscreen.', source: 'American Academy of Dermatology. 6 rosacea skin care tips dermatologists give their patients', source_url: 'https://www.aad.org/public/diseases/acne-and-rosacea/rosacea/6-rosacea-skin-care-tips-dermatologists-give-their-patients'}
] AS r
WITH r WHERE r.rel_type = 'RECOMMENDED_FOR'
MATCH (a:IngredientClass {id: trim(r.class_id)}), (s:SkinType {id: trim(r.skin_type_id)})
MERGE (a)-[x:RECOMMENDED_FOR]->(s)
ON CREATE SET x.type = 'recommendedFor', x.reason = r.reason, x.advice = r.advice,
              x.source = r.source, x.source_url = r.source_url;

// ---------- 5. Products, brands, ingredients in products ----------
UNWIND [
  {product_id: 'W01', label: 'CeraVe Resurfacing Retinol Serum 30ml', brand: 'CeraVe', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '41.90', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/cerave-resurfacing-retinol-serum-30ml/p/BP_87527', data_note: null},
  {product_id: 'W02', label: 'Olay Regenerist Retinol24 Serum 30ml', brand: 'Olay', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '39.10', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/olay-regenerist-retinol24-serum-30ml/p/BP_22392', data_note: 'Titanium dioxide here is likely an opacifier, not sun protection'},
  {product_id: 'W03', label: 'Neutrogena Visible Repair Serum (Retinol) 30ml', brand: 'Neutrogena', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '54.40', price_tier: 'Premium', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/neutrogena-visible-repair-serum-retinol-antioxidant-comfort-complex-30ml/p/BP_55500', data_note: null},
  {product_id: 'W04', label: 'Target Pro by Watsons Granactive Retinoid 1% Concentrated Serum 30ml', brand: 'Target Pro by Watsons', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '36.90', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/target-pro-by-watsons-granactive-retinoid%E2%84%A2-1-concentrated-serum-30ml/p/BP_93694', data_note: 'Watsons own brand'},
  {product_id: 'W06', label: 'Some By Mi Retinol Intense Reactivating Serum 30ml', brand: 'Some By Mi', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '34.90', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/some-by-mi-retinol-intense-reactivating-serum-suitable-for-sensitive-skin-30ml/p/BP_44899', data_note: 'Marketed as suitable for sensitive skin, yet contains fragrance'},
  {product_id: 'W07', label: 'Neogence Retinol Skin-Renewing Serum 30ml', brand: 'Neogence', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '99.90', price_tier: 'Premium', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/neogence-retinol-skin-renewing-serum-30ml/p/BP_67414', data_note: 'Lists ceramides under old names (Ceramide 2/3/6 II)'},
  {product_id: 'W08', label: 'Avène Hyaluron Activ Procedure Retinal Lifting Cream 30ml', brand: 'Avène', category: 'Moisturiser', gender: 'Unisex', spf: null, price_sgd: '97.93', price_tier: 'Premium', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/avène-hyaluron-activ-procedure-retinal-lifting-cream-30ml/p/BP_15905', data_note: null},
  {product_id: 'W10', label: 'Glad2Glow Peach Retinol Serum 17ml', brand: 'Glad2Glow', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '9.00', price_tier: 'Budget', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/glad2glow-peach-retinol-serum-17ml/p/BP_76310', data_note: null},
  {product_id: 'W11', label: 'The Ordinary Glycolic Acid 7% Toning Solution 240ml', brand: 'The Ordinary', category: 'Toner', gender: 'Unisex', spf: null, price_sgd: '22.50', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/the-ordinary-glycolic-acid-7-toning-solution-improves-the-appearance-of-skin-texture-with-continued-use-240ml/p/BP_47208', data_note: null},
  {product_id: 'W12', label: 'L\'Oréal Paris Glycolic Bright Peeling Water 128ml', brand: 'L\'Oréal Paris', category: 'Toner', gender: 'Unisex', spf: null, price_sgd: '49.40', price_tier: 'Premium', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/l-oreal-paris-skincare-glycolic-bright-peeling-water-with-brightening-glycolic-acid-exfoliates-128ml/p/BP_36057', data_note: null},
  {product_id: 'W13', label: 'Skintific Glycolic Acid Daily Clarifying Toner 80ml', brand: 'Skintific', category: 'Toner', gender: 'Unisex', spf: null, price_sgd: '13.32', price_tier: 'Budget', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/skintific-glycolic-acid-daily-clarifying-toner-to-gently-smooths-bumps-restores-skin-radiance-clears-pores-80ml/p/BP_76210', data_note: null},
  {product_id: 'W14', label: 'Bio-essence Bio-Water pH 2% Glycolic Niacinamide Toning Water 160ml', brand: 'Bio-essence', category: 'Toner', gender: 'Unisex', spf: null, price_sgd: '30.20', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/bio-water-sensitive-ph-2-glycolic-niacinamide-toning-water-to-refines-pores-brightens-skin-160ml/p/BP_49184', data_note: 'Named \'Sensitive\' but contains fragrance'},
  {product_id: 'W15', label: 'CeraVe SA Smoothing Cleanser 236ml', brand: 'CeraVe', category: 'Cleanser', gender: 'Unisex', spf: null, price_sgd: '25.50', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/cerave-salicylic-acid-smoothing-cleanser-fragrance-free-236ml/p/BP_76011', data_note: null},
  {product_id: 'W16', label: 'COSRX Salicylic Acid Daily Gentle Facial Cleanser 150ml', brand: 'COSRX', category: 'Cleanser', gender: 'Unisex', spf: null, price_sgd: '10.64', price_tier: 'Budget', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/cosrx-salicylic-acid-daily-gentle-facial-cleanser-150ml/p/BP_39487', data_note: null},
  {product_id: 'W17', label: 'Cetaphil Gentle Exfoliating SA Foaming Gel Cleanser 236ml', brand: 'Cetaphil', category: 'Cleanser', gender: 'Unisex', spf: null, price_sgd: '12.07', price_tier: 'Budget', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/cetaphil-gentle-exfoliating-sa-foaming-gel-cleanser-daily-use-236ml/p/BP_90317', data_note: null},
  {product_id: 'W18', label: 'Derma Lab Lumiclar Mandelic Renewal Serum 25ml', brand: 'Derma Lab', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '42.70', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/derma-lab-lumiclar-mandelic-renewal-serum-25ml/p/BP_17722', data_note: null},
  {product_id: 'W19', label: 'Dr. Wu Intensive Renewal Serum with Mandelic Acid 18% 5ml', brand: 'Dr. Wu', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '9.90', price_tier: 'Budget', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/dr.-wu-intensive-renewal-serum-with-mandelic-acid-18-refine-skin-texture-diminish-fine-lines-and-improve-skin-elasticity-and-firmness-5ml/p/BP_31103', data_note: null},
  {product_id: 'W20', label: 'Eucerin Dermopure Clinical Purifying Toner 200ml', brand: 'Eucerin', category: 'Toner', gender: 'Unisex', spf: null, price_sgd: '27.62', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/eucerin-dermopure-clinical-purifying-toner-200ml/p/BP_19212', data_note: null},
  {product_id: 'W23', label: 'Target Pro by Watsons Vitamin C15% Concentrated Serum 30ml', brand: 'Target Pro by Watsons', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '36.90', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/target-pro-by-watsons-vitamin-c15-concentrated-serum-30ml/p/BP_93693', data_note: 'Watsons own brand'},
  {product_id: 'W24', label: 'Skintific 10% Pure Vitamin C Brightening Fresh Serum 20ml', brand: 'Skintific', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '26.50', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/skintific-10-pure-vitamin-c-brightening-fresh-serum-20ml/p/BP_94515', data_note: null},
  {product_id: 'W25', label: 'Derma Lab Lumicar Pure Vitamin C 15% Serum 20ml', brand: 'Derma Lab', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '50.33', price_tier: 'Premium', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/derma-lab-lumicar-pure-vitamin-c-15-serum-20ml/p/BP_80378', data_note: 'Contains vitamin C and niacinamide together - real-world proof of myth C01'},
  {product_id: 'W27', label: 'andsons Brightening 23% Ascorbic Acid Serum (Made for Men\'s Skin) 30ml', brand: 'andsons', category: 'Serum', gender: 'Men', spf: null, price_sgd: '53.50', price_tier: 'Premium', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/andsons-brightening-23-ascorbic-acid-anti-ageing-serum-made-for-men-s-skin-30ml/p/BP_48878', data_note: 'CHECK: name says 23% ascorbic acid but the page\'s INCI list omits it; recorded from the product name'},
  {product_id: 'W28', label: 'Benzac Spots Treatment 5% (Benzoyl Peroxide) 60g', brand: 'Benzac', category: 'Treatment', gender: 'Unisex', spf: null, price_sgd: '19.90', price_tier: 'Budget', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/benzac-spots-treatment-5-anti-acne-pimple-gel-cream-with-benzoyl-peroxide-60g/p/BP_21967', data_note: 'Medicated product'},
  {product_id: 'W29', label: 'La Roche-Posay Effaclar Duo+M 40ml', brand: 'La Roche-Posay', category: 'Treatment', gender: 'Unisex', spf: null, price_sgd: '39.45', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/la-roche-posay-effaclar-duo-m-rapidly-clear-existing-spots-and-blackheads-40ml/p/BP_65336', data_note: null},
  {product_id: 'W30', label: 'Lululun Hydra Azelaic Acid Sheet Mask 7s', brand: 'Lululun', category: 'Mask', gender: 'Unisex', spf: null, price_sgd: '9.73', price_tier: 'Budget', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/lululun-hydra-azelaic-acid-sheet-mask-for-rough-skin-prevention-controls-breakouts-skin-conditioning-brightening-7s/p/BP_82627', data_note: 'Azelaic acid derivative + mandelic acid'},
  {product_id: 'W32', label: 'Neutrogena Hydro Boost Niacinamide Serum 30ml', brand: 'Neutrogena', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '36.90', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/neutrogena-hydro-boost-niacinamide-serum-30ml/p/BP_52500', data_note: null},
  {product_id: 'W33', label: 'Simple Booster Serum 10% Niacinamide 30ml', brand: 'Simple', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '28.15', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/booster-serum-10-niacinamide-vitamin-b3-deeply-hydrates-and-softens-even-dry-skin-30ml/p/BP_47688', data_note: null},
  {product_id: 'W34', label: 'CeraVe Moisturizing Cream 454g', brand: 'CeraVe', category: 'Moisturiser', gender: 'Unisex', spf: null, price_sgd: '45.50', price_tier: 'Premium', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/cerave-moisturizing-cream-help-restore-protective-skin-barrier-of-face-body-454g/p/BP_51152', data_note: null},
  {product_id: 'W36', label: 'Dr. Jart+ Ceramidin Cream 50ml', brand: 'Dr. Jart+', category: 'Moisturiser', gender: 'Unisex', spf: null, price_sgd: '52.50', price_tier: 'Premium', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/dr-jart-ceramidin-cream-50ml/p/BP_70677', data_note: 'Page says for everyone regardless of gender'},
  {product_id: 'W37', label: 'Skin1004 Madagascar Centella Soothing Cream 75ml', brand: 'Skin1004', category: 'Moisturiser', gender: 'Unisex', spf: null, price_sgd: '23.01', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/skin-1004-madagascar-centella-soothing-cream-help-repair-skin-barrier-75ml/p/BP_44057', data_note: null},
  {product_id: 'W38', label: 'Uriage Cica Daily Repairing Cream Concentrate 50ml', brand: 'Uriage', category: 'Moisturiser', gender: 'Unisex', spf: null, price_sgd: '45.90', price_tier: 'Premium', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/uriage-cica-daily-repairing-cream-concentrate-50ml/p/BP_60578', data_note: 'Page says for men and women'},
  {product_id: 'W39', label: 'La Roche-Posay Toleriane Soothing Toner 200ml', brand: 'La Roche-Posay', category: 'Toner', gender: 'Unisex', spf: null, price_sgd: '41.90', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/la-roche-posay-physiological-soothing-lotion-0-alcohol-face-toner-to-rebalance-ph-for-sensitive-skin-200ml/p/BP_45230', data_note: 'Alcohol-free toner for sensitive skin, but contains fragrance'},
  {product_id: 'W40', label: 'Bioré UV Aqua Rich Watery Essence SPF50+ 70g', brand: 'Bioré', category: 'Sunscreen', gender: 'Unisex', spf: '50', price_sgd: '17.25', price_tier: 'Budget', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/uv-aqua-rich-watery-essence-spf50-pa-sunscreen-micro-defense-uv-protection-suitable-for-face-body-70g/p/BP_62933', data_note: 'Chemical sunscreen'},
  {product_id: 'W41', label: 'Anessa Perfect UV Sunscreen Skincare Milk SPF50+ 60ml', brand: 'Anessa', category: 'Sunscreen', gender: 'Unisex', spf: '50', price_sgd: '47.00', price_tier: 'Premium', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/anessa-perfect-uv-sunscreen-skincare-milk-spf50-pa-for-face-body-60ml/p/BP_51505', data_note: 'Hybrid; Ethylhexyl Salicylate is a UV filter, NOT salicylic acid'},
  {product_id: 'W42', label: 'Beauty of Joseon Tinted Mineral Dayscreen SPF30 40ml', brand: 'Beauty of Joseon', category: 'Sunscreen', gender: 'Unisex', spf: '30', price_sgd: '32.95', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/beauty-of-joseon-tinted-mineral-dayscreen-15c-spf-30-pa-40ml/p/BP_73762', data_note: 'Mineral, fragrance-free'},
  {product_id: 'W43', label: 'Etat Pur Protective Mineral Fluid Facial Sunscreen SPF50+ 40ml', brand: 'Etat Pur', category: 'Sunscreen', gender: 'Unisex', spf: '50', price_sgd: '42.90', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/protective-mineral-fluid-facial-sunscreen-spf50-suitable-for-all-skin-types-sensitive-skin-40ml/p/BP_50988', data_note: 'Mineral and marketed for sensitive skin, but contains fragrance'},
  {product_id: 'W44', label: 'Neutrogena Hydro Boost Hydrating Fluid SPF50 50ml', brand: 'Neutrogena', category: 'Sunscreen', gender: 'Unisex', spf: '50', price_sgd: '33.90', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/neutrogena-hydro-boost-hydrating-fluid-spf50-50ml/p/BP_78139', data_note: 'Fragrance-free'},
  {product_id: 'W45', label: 'andsons Oil Control 3% Niacinamide Daily Cleanser (Made for Men\'s Skin) 100ml', brand: 'andsons', category: 'Cleanser', gender: 'Men', spf: null, price_sgd: '31.30', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/andsons-oil-control-3-niacinamide-daily-cleanser-made-for-men-s-skin-100ml/p/BP_48877', data_note: null},
  {product_id: 'W46', label: 'Garnier Men Oil Control 3-in-1 Charcoal Foam 100ml', brand: 'Garnier Men', category: 'Cleanser', gender: 'Men', spf: null, price_sgd: '8.88', price_tier: 'Budget', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/garnier-men-men-oil-control-3-in-1-charcoal-foam-oil-control-100ml/p/BP_59002', data_note: null},
  {product_id: 'W47', label: 'Men\'s Bioré Double Oil Control Facial Wash 130g', brand: 'Men\'s Bioré', category: 'Cleanser', gender: 'Men', spf: null, price_sgd: '10.10', price_tier: 'Budget', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/men-s-biore-double-oil-control-facial-wash-130g/p/BP_92696', data_note: null},
  {product_id: 'W48', label: 'Nivea Men Multi Protecting Post Shave Balm 100ml', brand: 'Nivea Men', category: 'Aftershave', gender: 'Men', spf: null, price_sgd: '10.90', price_tier: 'Budget', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/nivea-men-multi-protecting-post-shave-balm-100ml/p/BP_46924', data_note: null},
  {product_id: 'W49', label: 'Anthony Aftershave Balm 90ml', brand: 'Anthony', category: 'Aftershave', gender: 'Men', spf: null, price_sgd: '46.90', price_tier: 'Premium', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/anthony-aftershave-balm-for-all-skin-types-natural-botanical-extracts-90ml/p/BP_34442', data_note: 'Aftershave that contains a retinoid ester and a UV filter'},
  {product_id: 'W50', label: 'Anessa Men Multi-Control UV Sunscreen Gel 40g', brand: 'Anessa', category: 'Sunscreen', gender: 'Men', spf: '50', price_sgd: '18.70', price_tier: 'Budget', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/anessa-men-multi-control-uv-sunscreen-gel-40g/p/BP_13802', data_note: null},
  {product_id: 'W51', label: 'Biotherm Homme T-Pur Oil Control & Hydration Advance Gel 50ml', brand: 'Biotherm Homme', category: 'Moisturiser', gender: 'Men', spf: null, price_sgd: '52.00', price_tier: 'Premium', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/biotherm-t-pur-oil-control-hydration-advance-gel-50ml/p/BP_70917', data_note: 'Moisturiser that also contains two exfoliating acids'},
  {product_id: 'W52', label: 'Biotherm Homme T-Pur Dual Action Anti-Oil & Shine Lotion 200ml', brand: 'Biotherm Homme', category: 'Toner', gender: 'Men', spf: null, price_sgd: '35.00', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/biotherm-t-pur-dual-action-anti-oil-shine-lotion-200ml/p/BP_70485', data_note: null},
  {product_id: 'W53', label: 'Glad2Glow Pomegranate + Niacinamide Power Bright Serum 17ml', brand: 'Glad2Glow', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '9.00', price_tier: 'Budget', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/glad2glow-pomegranate-niacinamide-power-bright-serum-17ml/p/BP_76311', data_note: 'Budget, fragrance-free'},
  {product_id: 'W54', label: 'Skintific 10% Niacinamide Brightening Serum 20ml', brand: 'Skintific', category: 'Serum', gender: 'Unisex', spf: null, price_sgd: '19.20', price_tier: 'Budget', retailer: 'Watsons Singapore', url: 'https://watsons.com.sg/10-niacinamide-brightening-serum-to-fades-dark-spots-blemishes-smooths-evens-skin-tone-20ml/p/BP_76225', data_note: 'Budget, contains fragrance'},
  {product_id: 'W55', label: 'Hada Labo Hydrating Lotion Light 170ml', brand: 'Hada Labo', category: 'Toner', gender: 'Unisex', spf: null, price_sgd: '25.15', price_tier: 'Mid', retailer: 'Watsons Singapore', url: 'https://www.watsons.com.sg/hydrating-lotion-light-light-weight-lotion-with-4-types-of-hyaluronic-acid-amino-acid-ceramide-for-healthy-skin-170ml/p/BP_79612', data_note: 'Gentle hydrating toner: no acids, alcohol or fragrance'}
] AS r
MERGE (p:Product {id: trim(r.product_id)})
ON CREATE SET p.label = r.label, p.type = r.category, p.price_sgd = toFloat(r.price_sgd),
              p.gender = r.gender, p.spf = toInteger(r.spf), p.price_tier = r.price_tier,
              p.retailer = r.retailer, p.url = r.url, p.data_note = r.data_note
WITH p, r WHERE r.brand IS NOT NULL AND trim(r.brand) <> ''
MERGE (b:Brand {id: trim(r.brand)}) ON CREATE SET b.label = trim(r.brand), b.type = 'Brand'
MERGE (p)-[:HAS_BRAND {type: 'hasBrand'}]->(b);

UNWIND [
  {product_id: 'W01', ingredient_id: 'retinol'},
  {product_id: 'W01', ingredient_id: 'niacinamide'},
  {product_id: 'W01', ingredient_id: 'ceramide_np'},
  {product_id: 'W01', ingredient_id: 'ceramide_ap'},
  {product_id: 'W01', ingredient_id: 'ceramide_eop'},
  {product_id: 'W01', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W01', ingredient_id: 'alcohol'},
  {product_id: 'W02', ingredient_id: 'retinol'},
  {product_id: 'W02', ingredient_id: 'retinyl_propionate'},
  {product_id: 'W02', ingredient_id: 'niacinamide'},
  {product_id: 'W02', ingredient_id: 'palmitoyl_pentapeptide_4'},
  {product_id: 'W02', ingredient_id: 'glycerin'},
  {product_id: 'W02', ingredient_id: 'titanium_dioxide'},
  {product_id: 'W03', ingredient_id: 'retinol'},
  {product_id: 'W03', ingredient_id: 'glycerin'},
  {product_id: 'W03', ingredient_id: 'parfum'},
  {product_id: 'W04', ingredient_id: 'hpr'},
  {product_id: 'W04', ingredient_id: 'bakuchiol'},
  {product_id: 'W04', ingredient_id: 'niacinamide'},
  {product_id: 'W04', ingredient_id: 'centella_extract'},
  {product_id: 'W04', ingredient_id: 'glycerin'},
  {product_id: 'W04', ingredient_id: 'alcohol'},
  {product_id: 'W06', ingredient_id: 'retinol'},
  {product_id: 'W06', ingredient_id: 'retinal'},
  {product_id: 'W06', ingredient_id: 'bakuchiol'},
  {product_id: 'W06', ingredient_id: 'niacinamide'},
  {product_id: 'W06', ingredient_id: 'palmitoyl_tripeptide_1'},
  {product_id: 'W06', ingredient_id: 'ceramide_np'},
  {product_id: 'W06', ingredient_id: 'panthenol'},
  {product_id: 'W06', ingredient_id: 'centella_extract'},
  {product_id: 'W06', ingredient_id: 'madecassoside'},
  {product_id: 'W06', ingredient_id: 'glycerin'},
  {product_id: 'W06', ingredient_id: 'parfum'},
  {product_id: 'W07', ingredient_id: 'retinyl_palmitate'},
  {product_id: 'W07', ingredient_id: 'retinol'},
  {product_id: 'W07', ingredient_id: 'retinal'},
  {product_id: 'W07', ingredient_id: 'bakuchiol'},
  {product_id: 'W07', ingredient_id: 'niacinamide'},
  {product_id: 'W07', ingredient_id: 'palmitoyl_tripeptide_1'},
  {product_id: 'W07', ingredient_id: 'palmitoyl_tetrapeptide_7'},
  {product_id: 'W07', ingredient_id: 'ceramide_np'},
  {product_id: 'W07', ingredient_id: 'ceramide_ns'},
  {product_id: 'W07', ingredient_id: 'ceramide_ap'},
  {product_id: 'W07', ingredient_id: 'glycerin'},
  {product_id: 'W08', ingredient_id: 'retinal'},
  {product_id: 'W08', ingredient_id: 'niacinamide'},
  {product_id: 'W08', ingredient_id: 'glycerin'},
  {product_id: 'W08', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W10', ingredient_id: 'retinol'},
  {product_id: 'W10', ingredient_id: 'retinyl_propionate'},
  {product_id: 'W10', ingredient_id: 'hpr'},
  {product_id: 'W10', ingredient_id: 'madecassoside'},
  {product_id: 'W10', ingredient_id: 'allantoin'},
  {product_id: 'W10', ingredient_id: 'glycerin'},
  {product_id: 'W10', ingredient_id: 'parfum'},
  {product_id: 'W11', ingredient_id: 'glycolic_acid'},
  {product_id: 'W11', ingredient_id: 'glycerin'},
  {product_id: 'W12', ingredient_id: 'glycolic_acid'},
  {product_id: 'W12', ingredient_id: 'ascorbyl_glucoside'},
  {product_id: 'W12', ingredient_id: 'panthenol'},
  {product_id: 'W12', ingredient_id: 'glycerin'},
  {product_id: 'W13', ingredient_id: 'glycolic_acid'},
  {product_id: 'W13', ingredient_id: 'lactic_acid'},
  {product_id: 'W13', ingredient_id: 'lactobionic_acid'},
  {product_id: 'W13', ingredient_id: 'niacinamide'},
  {product_id: 'W13', ingredient_id: 'ceramide_np'},
  {product_id: 'W13', ingredient_id: 'ceramide_ns'},
  {product_id: 'W13', ingredient_id: 'ceramide_as'},
  {product_id: 'W13', ingredient_id: 'ceramide_eop'},
  {product_id: 'W13', ingredient_id: 'ceramide_ap'},
  {product_id: 'W13', ingredient_id: 'centella_extract'},
  {product_id: 'W13', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W13', ingredient_id: 'glycerin'},
  {product_id: 'W14', ingredient_id: 'glycolic_acid'},
  {product_id: 'W14', ingredient_id: 'gluconolactone'},
  {product_id: 'W14', ingredient_id: 'niacinamide'},
  {product_id: 'W14', ingredient_id: 'glycerin'},
  {product_id: 'W14', ingredient_id: 'parfum'},
  {product_id: 'W15', ingredient_id: 'salicylic_acid'},
  {product_id: 'W15', ingredient_id: 'gluconolactone'},
  {product_id: 'W15', ingredient_id: 'niacinamide'},
  {product_id: 'W15', ingredient_id: 'ceramide_np'},
  {product_id: 'W15', ingredient_id: 'ceramide_ap'},
  {product_id: 'W15', ingredient_id: 'ceramide_eop'},
  {product_id: 'W15', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W15', ingredient_id: 'glycerin'},
  {product_id: 'W16', ingredient_id: 'salicylic_acid'},
  {product_id: 'W16', ingredient_id: 'glycerin'},
  {product_id: 'W16', ingredient_id: 'parfum'},
  {product_id: 'W17', ingredient_id: 'mandelic_acid'},
  {product_id: 'W17', ingredient_id: 'salicylic_acid'},
  {product_id: 'W17', ingredient_id: 'gluconolactone'},
  {product_id: 'W17', ingredient_id: 'niacinamide'},
  {product_id: 'W17', ingredient_id: 'panthenol'},
  {product_id: 'W17', ingredient_id: 'glycerin'},
  {product_id: 'W18', ingredient_id: 'mandelic_acid'},
  {product_id: 'W18', ingredient_id: 'lactic_acid'},
  {product_id: 'W18', ingredient_id: 'ceramide_np'},
  {product_id: 'W18', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W19', ingredient_id: 'mandelic_acid'},
  {product_id: 'W19', ingredient_id: 'panthenol'},
  {product_id: 'W19', ingredient_id: 'centella_extract'},
  {product_id: 'W19', ingredient_id: 'allantoin'},
  {product_id: 'W19', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W20', ingredient_id: 'glycolic_acid'},
  {product_id: 'W20', ingredient_id: 'lactic_acid'},
  {product_id: 'W20', ingredient_id: 'gluconolactone'},
  {product_id: 'W20', ingredient_id: 'glycerin'},
  {product_id: 'W20', ingredient_id: 'alcohol_denat'},
  {product_id: 'W23', ingredient_id: 'ascorbic_acid'},
  {product_id: 'W23', ingredient_id: 'centella_extract'},
  {product_id: 'W23', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W24', ingredient_id: 'ascorbic_acid'},
  {product_id: 'W24', ingredient_id: 'glycerin'},
  {product_id: 'W25', ingredient_id: 'ascorbic_acid'},
  {product_id: 'W25', ingredient_id: 'ethyl_ascorbic_acid'},
  {product_id: 'W25', ingredient_id: 'niacinamide'},
  {product_id: 'W25', ingredient_id: 'ceramide_np'},
  {product_id: 'W25', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W25', ingredient_id: 'glycerin'},
  {product_id: 'W27', ingredient_id: 'ascorbic_acid'},
  {product_id: 'W27', ingredient_id: 'allantoin'},
  {product_id: 'W27', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W27', ingredient_id: 'glycerin'},
  {product_id: 'W28', ingredient_id: 'benzoyl_peroxide'},
  {product_id: 'W28', ingredient_id: 'glycerin'},
  {product_id: 'W29', ingredient_id: 'salicylic_acid'},
  {product_id: 'W29', ingredient_id: 'capryloyl_salicylic_acid'},
  {product_id: 'W29', ingredient_id: 'niacinamide'},
  {product_id: 'W29', ingredient_id: 'glycerin'},
  {product_id: 'W29', ingredient_id: 'parfum'},
  {product_id: 'W30', ingredient_id: 'potassium_azeloyl_diglycinate'},
  {product_id: 'W30', ingredient_id: 'mandelic_acid'},
  {product_id: 'W30', ingredient_id: 'niacinamide'},
  {product_id: 'W30', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W30', ingredient_id: 'glycerin'},
  {product_id: 'W32', ingredient_id: 'niacinamide'},
  {product_id: 'W32', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W32', ingredient_id: 'glycerin'},
  {product_id: 'W33', ingredient_id: 'niacinamide'},
  {product_id: 'W33', ingredient_id: 'panthenol'},
  {product_id: 'W33', ingredient_id: 'glycerin'},
  {product_id: 'W34', ingredient_id: 'ceramide_np'},
  {product_id: 'W34', ingredient_id: 'ceramide_ap'},
  {product_id: 'W34', ingredient_id: 'ceramide_eop'},
  {product_id: 'W34', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W34', ingredient_id: 'glycerin'},
  {product_id: 'W36', ingredient_id: 'ceramide_np'},
  {product_id: 'W36', ingredient_id: 'ceramide_ap'},
  {product_id: 'W36', ingredient_id: 'ceramide_as'},
  {product_id: 'W36', ingredient_id: 'ceramide_ns'},
  {product_id: 'W36', ingredient_id: 'ceramide_eop'},
  {product_id: 'W36', ingredient_id: 'palmitoyl_pentapeptide_4'},
  {product_id: 'W36', ingredient_id: 'panthenol'},
  {product_id: 'W36', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W36', ingredient_id: 'glycerin'},
  {product_id: 'W37', ingredient_id: 'ceramide_eop'},
  {product_id: 'W37', ingredient_id: 'ceramide_ns'},
  {product_id: 'W37', ingredient_id: 'ceramide_np'},
  {product_id: 'W37', ingredient_id: 'ceramide_ap'},
  {product_id: 'W37', ingredient_id: 'centella_extract'},
  {product_id: 'W37', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W37', ingredient_id: 'glycerin'},
  {product_id: 'W38', ingredient_id: 'panthenol'},
  {product_id: 'W38', ingredient_id: 'centella_extract'},
  {product_id: 'W38', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W38', ingredient_id: 'glycerin'},
  {product_id: 'W39', ingredient_id: 'glycerin'},
  {product_id: 'W39', ingredient_id: 'parfum'},
  {product_id: 'W40', ingredient_id: 'octinoxate'},
  {product_id: 'W40', ingredient_id: 'ethylhexyl_triazone'},
  {product_id: 'W40', ingredient_id: 'dhhb'},
  {product_id: 'W40', ingredient_id: 'bemotrizinol'},
  {product_id: 'W40', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W40', ingredient_id: 'glycerin'},
  {product_id: 'W40', ingredient_id: 'alcohol'},
  {product_id: 'W40', ingredient_id: 'parfum'},
  {product_id: 'W41', ingredient_id: 'zinc_oxide'},
  {product_id: 'W41', ingredient_id: 'titanium_dioxide'},
  {product_id: 'W41', ingredient_id: 'octocrylene'},
  {product_id: 'W41', ingredient_id: 'ethylhexyl_salicylate'},
  {product_id: 'W41', ingredient_id: 'dhhb'},
  {product_id: 'W41', ingredient_id: 'homosalate'},
  {product_id: 'W41', ingredient_id: 'bemotrizinol'},
  {product_id: 'W41', ingredient_id: 'ethylhexyl_triazone'},
  {product_id: 'W41', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W41', ingredient_id: 'glycerin'},
  {product_id: 'W41', ingredient_id: 'alcohol'},
  {product_id: 'W41', ingredient_id: 'parfum'},
  {product_id: 'W42', ingredient_id: 'zinc_oxide'},
  {product_id: 'W42', ingredient_id: 'titanium_dioxide'},
  {product_id: 'W42', ingredient_id: 'ceramide_np'},
  {product_id: 'W43', ingredient_id: 'zinc_oxide'},
  {product_id: 'W43', ingredient_id: 'titanium_dioxide'},
  {product_id: 'W43', ingredient_id: 'parfum'},
  {product_id: 'W44', ingredient_id: 'dhhb'},
  {product_id: 'W44', ingredient_id: 'ethylhexyl_triazone'},
  {product_id: 'W44', ingredient_id: 'bisoctrizole'},
  {product_id: 'W44', ingredient_id: 'bemotrizinol'},
  {product_id: 'W44', ingredient_id: 'titanium_dioxide'},
  {product_id: 'W44', ingredient_id: 'sodium_ascorbyl_phosphate'},
  {product_id: 'W44', ingredient_id: 'niacinamide'},
  {product_id: 'W44', ingredient_id: 'panthenol'},
  {product_id: 'W44', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W44', ingredient_id: 'glycerin'},
  {product_id: 'W45', ingredient_id: 'niacinamide'},
  {product_id: 'W45', ingredient_id: 'panthenol'},
  {product_id: 'W45', ingredient_id: 'glycerin'},
  {product_id: 'W46', ingredient_id: 'salicylic_acid'},
  {product_id: 'W46', ingredient_id: 'ascorbyl_glucoside'},
  {product_id: 'W46', ingredient_id: 'glycerin'},
  {product_id: 'W46', ingredient_id: 'parfum'},
  {product_id: 'W46', ingredient_id: 'linalool'},
  {product_id: 'W46', ingredient_id: 'limonene'},
  {product_id: 'W46', ingredient_id: 'menthol'},
  {product_id: 'W47', ingredient_id: 'glycerin'},
  {product_id: 'W47', ingredient_id: 'parfum'},
  {product_id: 'W47', ingredient_id: 'menthol'},
  {product_id: 'W47', ingredient_id: 'peppermint_extract'},
  {product_id: 'W48', ingredient_id: 'panthenol'},
  {product_id: 'W48', ingredient_id: 'glycerin'},
  {product_id: 'W48', ingredient_id: 'alcohol_denat'},
  {product_id: 'W48', ingredient_id: 'parfum'},
  {product_id: 'W48', ingredient_id: 'limonene'},
  {product_id: 'W48', ingredient_id: 'linalool'},
  {product_id: 'W49', ingredient_id: 'retinyl_palmitate'},
  {product_id: 'W49', ingredient_id: 'ascorbyl_palmitate'},
  {product_id: 'W49', ingredient_id: 'panthenol'},
  {product_id: 'W49', ingredient_id: 'allantoin'},
  {product_id: 'W49', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W49', ingredient_id: 'glycerin'},
  {product_id: 'W49', ingredient_id: 'octinoxate'},
  {product_id: 'W49', ingredient_id: 'limonene'},
  {product_id: 'W49', ingredient_id: 'menthoxypropanediol'},
  {product_id: 'W50', ingredient_id: 'zinc_oxide'},
  {product_id: 'W50', ingredient_id: 'titanium_dioxide'},
  {product_id: 'W50', ingredient_id: 'octinoxate'},
  {product_id: 'W50', ingredient_id: 'dhhb'},
  {product_id: 'W50', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W50', ingredient_id: 'glycerin'},
  {product_id: 'W50', ingredient_id: 'alcohol'},
  {product_id: 'W50', ingredient_id: 'parfum'},
  {product_id: 'W50', ingredient_id: 'linalool'},
  {product_id: 'W50', ingredient_id: 'limonene'},
  {product_id: 'W51', ingredient_id: 'salicylic_acid'},
  {product_id: 'W51', ingredient_id: 'capryloyl_salicylic_acid'},
  {product_id: 'W51', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W51', ingredient_id: 'glycerin'},
  {product_id: 'W51', ingredient_id: 'alcohol_denat'},
  {product_id: 'W51', ingredient_id: 'parfum'},
  {product_id: 'W51', ingredient_id: 'linalool'},
  {product_id: 'W51', ingredient_id: 'limonene'},
  {product_id: 'W51', ingredient_id: 'menthol'},
  {product_id: 'W52', ingredient_id: 'salicylic_acid'},
  {product_id: 'W52', ingredient_id: 'glycerin'},
  {product_id: 'W52', ingredient_id: 'alcohol_denat'},
  {product_id: 'W52', ingredient_id: 'parfum'},
  {product_id: 'W52', ingredient_id: 'linalool'},
  {product_id: 'W52', ingredient_id: 'limonene'},
  {product_id: 'W53', ingredient_id: 'niacinamide'},
  {product_id: 'W53', ingredient_id: 'ceramide_np'},
  {product_id: 'W53', ingredient_id: 'centella_extract'},
  {product_id: 'W53', ingredient_id: 'allantoin'},
  {product_id: 'W53', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W53', ingredient_id: 'glycerin'},
  {product_id: 'W54', ingredient_id: 'niacinamide'},
  {product_id: 'W54', ingredient_id: 'ceramide_np'},
  {product_id: 'W54', ingredient_id: 'ceramide_as'},
  {product_id: 'W54', ingredient_id: 'ceramide_ap'},
  {product_id: 'W54', ingredient_id: 'ceramide_ns'},
  {product_id: 'W54', ingredient_id: 'centella_extract'},
  {product_id: 'W54', ingredient_id: 'allantoin'},
  {product_id: 'W54', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W54', ingredient_id: 'parfum'},
  {product_id: 'W55', ingredient_id: 'sodium_hyaluronate'},
  {product_id: 'W55', ingredient_id: 'glycerin'}
] AS r
MATCH (p:Product {id: trim(r.product_id)}), (i:Ingredient {id: trim(r.ingredient_id)})
MERGE (p)-[:CONTAINS {type: 'contains'}]->(i);

// Rinse-off vs leave-on: cleansers are washed off within about a minute,
// so the queries treat them differently (derived from the product type)
MATCH (p:Product)
SET p.application = CASE WHEN p.type = 'Cleanser' THEN 'rinse_off' ELSE 'leave_on' END;

// ---------- 6. Users and their routines ----------
UNWIND [
  {user_id: 'demo_oily', label: 'Demo user A (woman, oily, acne-prone)', gender: 'Women', skin_type_id: 'oily', concern_ids: 'acne|hyperpigmentation'},
  {user_id: 'demo_sensitive', label: 'Demo user B (woman, sensitive, redness)', gender: 'Women', skin_type_id: 'sensitive', concern_ids: 'redness|signs_of_aging'},
  {user_id: 'demo_men', label: 'Demo user C (man, oily, shaves daily)', gender: 'Men', skin_type_id: 'oily', concern_ids: 'oiliness|acne'}
] AS r
MERGE (u:User {id: trim(r.user_id)})
ON CREATE SET u.label = r.label, u.type = 'User', u.gender = r.gender
WITH u, r
MATCH (s:SkinType {id: trim(r.skin_type_id)})
MERGE (u)-[:HAS_SKIN_TYPE {type: 'hasSkinType'}]->(s)
WITH u, r
UNWIND split(r.concern_ids, '|') AS cid
MATCH (k:Concern {id: trim(cid)})
MERGE (u)-[:HAS_CONCERN {type: 'hasConcern'}]->(k);

UNWIND [
  {user_id: 'demo_oily', product_id: 'W16', slot: 'AM', step_order: '1'},
  {user_id: 'demo_oily', product_id: 'W24', slot: 'AM', step_order: '2'},
  {user_id: 'demo_oily', product_id: 'W33', slot: 'AM', step_order: '3'},
  {user_id: 'demo_oily', product_id: 'W28', slot: 'AM', step_order: '4'},
  {user_id: 'demo_oily', product_id: 'W16', slot: 'PM', step_order: '1'},
  {user_id: 'demo_oily', product_id: 'W11', slot: 'PM', step_order: '2'},
  {user_id: 'demo_oily', product_id: 'W01', slot: 'PM', step_order: '3'},
  {user_id: 'demo_oily', product_id: 'W34', slot: 'PM', step_order: '4'},
  {user_id: 'demo_sensitive', product_id: 'W39', slot: 'AM', step_order: '1'},
  {user_id: 'demo_sensitive', product_id: 'W41', slot: 'AM', step_order: '2'},
  {user_id: 'demo_sensitive', product_id: 'W20', slot: 'PM', step_order: '1'},
  {user_id: 'demo_sensitive', product_id: 'W06', slot: 'PM', step_order: '2'},
  {user_id: 'demo_sensitive', product_id: 'W29', slot: 'PM', step_order: '3'},
  {user_id: 'demo_sensitive', product_id: 'W37', slot: 'PM', step_order: '4'},
  {user_id: 'demo_men', product_id: 'W46', slot: 'AM', step_order: '1'},
  {user_id: 'demo_men', product_id: 'W48', slot: 'AM', step_order: '2'},
  {user_id: 'demo_men', product_id: 'W51', slot: 'AM', step_order: '3'},
  {user_id: 'demo_men', product_id: 'W47', slot: 'PM', step_order: '1'},
  {user_id: 'demo_men', product_id: 'W52', slot: 'PM', step_order: '2'},
  {user_id: 'demo_men', product_id: 'W04', slot: 'PM', step_order: '3'}
] AS r
MATCH (u:User {id: trim(r.user_id)}), (p:Product {id: trim(r.product_id)})
MERGE (u)-[x:USES {slot: trim(r.slot)}]->(p)
ON CREATE SET x.type = 'uses', x.step_order = toInteger(r.step_order);

// ---------- 7. Check ----------
MATCH (n) RETURN labels(n)[0] AS NodeLabel, count(*) AS Count ORDER BY NodeLabel;
