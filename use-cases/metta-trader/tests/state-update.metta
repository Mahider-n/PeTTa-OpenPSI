!(import! &self ../rule-ops)
!(import! &self ../world)
!(import! &self ../utils)

(= (testSTV) (1.0 0.9))

;; Test for adding an item
!(test (addItem ((PLANET A)) FOOD (testSTV)) ((PLANET A) ((HAS FOOD) (testSTV))))
!(test (addItem ((PLANET A) ((HAS FUEL) (0.8 0.8))) FOOD (testSTV)) ((PLANET A) ((HAS FUEL) (0.8 0.8)) ((HAS FOOD) (testSTV))))
!(test (addItem ((PLANET A) ((HAS FOOD) (0.1 0.1))) FOOD (testSTV)) ((PLANET A) ((HAS FOOD) (testSTV))))

;; Test for removing an item
!(test (removeItem (((HAS FOOD) (testSTV)) ((PLANET A) (testSTV))) FOOD) (((PLANET A) (testSTV))))
!(test (removeItem (((HAS FUEL) (0.8 0.8)) ((PLANET A) (testSTV))) FOOD) (((HAS FUEL) (0.8 0.8)) ((PLANET A) (testSTV))))
!(test (removeItem (((PLANET A) (testSTV))) FOOD) (((PLANET A) (testSTV))))


;; Test for updating planet 
!(test (updatePlanet (((PLANET A) (testSTV))) B) (((PLANET B) (testSTV))))
!(test (updatePlanet (((PLANET A) (testSTV)) ((HAS FOOD) (testSTV))) B) (((PLANET B) (testSTV)) ((HAS FOOD) (testSTV))))
!(test (updatePlanet (((PLANET A) (testSTV))) C) (((PLANET C) (testSTV))))