!(import! &self ../rule-ops)
!(import! &self ../world)
!(import! &self ../utils)

(= (testSTV) (1.0 0.9))

;; Test for getting an item
!(test (getItem (((HAS FOOD) (testSTV)) ((PLANET A) (testSTV)))) (FOOD (testSTV)))
!(test (getItem (((PLANET A) (testSTV)) ((HAS FOOD) (testSTV)))) (FOOD (testSTV)))
!(test (getItem (((PLANET C) (testSTV)) ((HAS FUEL) (0.8 0.8)))) (FUEL (0.8 0.8)))

;; Test for evaluating state
!(test (evaluateState (((HAS FOOD) (1.0 0.9)) ((PLANET A) (1.0 0.9))) 10) 25)
!(test (evaluateState (((HAS FUEL) (1.0 0.9)) ((PLANET B) (1.0 0.9))) 0) 16)
!(test (evaluateState (((HAS METAL) (1.0 0.9)) ((PLANET C) (1.0 0.9))) 23) 38)

;; Test for getting the planet
!(test (getPlanetFromContexts (((PLANET C) (testSTV)))) C)
!(test (getPlanetFromContexts (((PLANET A) (testSTV)) ((HAS METAL) (testSTV)))) A)
!(test (getPlanetFromContexts (((HAS METAL) (testSTV)) ((PLANET A) (testSTV)))) A)