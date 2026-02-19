;; Travel Info
(TRAVEL_COST A B 1)
(TRAVEL_COST A C 1)
(TRAVEL_COST B A 1)
(TRAVEL_COST B C 1)
(TRAVEL_COST C A 1)
(TRAVEL_COST C B 1)


(FOOD A 8)
(FOOD B 20)
(FOOD C 18)

(METAL A 15)
(METAL B 8)
(METAL C 22)

(FUEL A 25)
(FUEL B 18)
(FUEL C 5)

(AVG_PRICE FOOD 15)
(AVG_PRICE METAL 15)
(AVG_PRICE FUEL 16)

;; Helper Functions
(= (getTravelCost $source $destination) 1)

(= (getFoodCost $planet) (
    match &self (FOOD $planet $cost) $cost
))

(= (getMetalCost $planet) (
    match &self (METAL $planet $cost) $cost
))

(= (getFuelCost $planet) (
    match &self (FUEL $planet $cost) $cost
))

(= (getItemPrice $item $planet) (
    case $item (
        (FOOD (case $planet (
            (A 8)
            (B 20)
            (C 18)
        )))
        (FUEL (case $planet (
            (A 25)
            (B 18)
            (C 5)
        )))
        (METAL (case $planet (
            (A 15)
            (B 8)
            (C 22)
        )))
    )
))

(= (getAvgPrice $item) (
    case $item (
        (FOOD 15)
        (FUEL 16)
        (METAL 15)
    )
))

;; Travel Cost Tests
!(test (getTravelCost A B) 1)
!(test (getTravelCost B C) 1)

;; Item Cost Tests
!(test (getItemPrice FOOD C) 18)
!(test (getItemPrice FUEL B) 18)
!(test (getItemPrice METAL A) 15)
!(test (getItemPrice FOOD A) 8)

;; Average Cost Tests
!(test (getAvgPrice FOOD) 15)
!(test (getAvgPrice FUEL) 16)