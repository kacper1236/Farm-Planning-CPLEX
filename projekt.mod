/*********************************************
 * OPL 22.1.1.0 Model
 * Author: Rogal
 * Creation Date: 11 kwi 2024 at 10:29:24
 *********************************************/

int NbOfLands = ...;
range LandNbs = 1..NbOfLands;

int Years = ...;
range YearNbs = 1..Years;

int MaxAge = ...;
range AgeNbs = 1..MaxAge;

range CowAges = 2..MaxAge-1;

float InitialCows[AgeNbs] = ...;
float HeifSurvival = ...;
float CowSurvival = ...;
float CalfRate = ...;
float HeifFraction = ...;
float InitialCap = ...;
float GrainPerCow = ...;
float SugarbeetPerCow = ...;
float GrainPerAcre[LandNbs] = ...;
float GrainAcre[LandNbs] = ...;
float SugarbeetPerAcre = ...;
float HeifAcre = ...;
float CowAcre = ...;
float Acres = ...;
float HeifLabor = ...;
float CowLabor = ...;
float Labor = ...;
float GrainLabor = ...;
float SugarbeetLabor = ...;
float DownCowChange = ...;
float UpCowChange = ...;
float BullockSellPrice = ...;
float HeifSellPrice = ...;
float CowSellPrice = ...;
float MilkPerCowPrice = ...;
float GrainSellPrice = ...;
float SugarbeetSellPrice = ...;
float GrainBuyPrice = ...;
float SugarbeetBuyPrice = ...;
float LaborFixCost = ...;
float LaborCost = ...;
float HeifCost = ...;
float CowCost = ...;
float GrainGrowCost = ...;
float SugarbeetGrowCost = ...;
int   LoanTerm = ...;
float Repay = ...;


float InitialCowsTotal = sum(i in CowAges) InitialCows[i];

dvar float+ CapAdd[YearNbs];
dvar float+ Profit[YearNbs];
dvar float+ HeifSell[YearNbs];
dvar float+ CowTotal[YearNbs];
dvar float+ Cow[AgeNbs,YearNbs];
dvar float+ SmallCow[YearNbs];
dvar float+ GrainGrow[l in LandNbs][y in YearNbs] in 0..GrainPerAcre[l]*GrainAcre[l];
dvar float+ GrainSell[YearNbs];
dvar float+ GrowBuy[YearNbs];
dvar float+ SugarbeetSell[YearNbs];
dvar float+ SugarbeetBuy[YearNbs];
dvar float+ SugarbeetGrow[YearNbs];
dvar float+ LaborYear[YearNbs];

dexpr float objective = sum(i in YearNbs) Profit[i] - Repay * 
    (sum(i in YearNbs) ((LoanTerm-Years-1+i) * CapAdd[i]));

maximize objective;

subject to {
  //kacper
  forall(y in YearNbs) {
    countTotalCow: CowTotal[y] == sum(j in CowAges) Cow[j][y];
  }

  // Cows move from one age to the next
  //mateusz
  forall(y in 1..Years-1) {
    Cow[1][y+1] == HeifSurvival * SmallCow[y];
    Cow[2][y+1] == HeifSurvival * Cow[1][y];
    forall(j in CowAges) {
      Cow[j+1][y+1] == CowSurvival * Cow[j][y];
    }
  }
  //hubert
  forall(y in YearNbs) {
    countSellHeif:  SmallCow[y] == CalfRate * HeifFraction * CowTotal[y] - HeifSell[y];
  }
    
  // Initial conditions
  //kacper
  Cow[1][1] == HeifSurvival * InitialCows[1];
  Cow[2][1] == HeifSurvival * InitialCows[2];
  forall(j in 3..MaxAge) {
    Cow[j][1] == CowSurvival * InitialCows[j];
  }
  //mateusz
  forall(y in YearNbs) {
    countAccommodation: SmallCow[y] + Cow[1][y] + CowTotal[y] <= InitialCap + sum(k in YearNbs: k <= y) CapAdd[k];
  }
  //hubert
  forall(y in YearNbs) {
    countGrainConsuption: CowTotal[y] * GrainPerCow <= sum(l in LandNbs) GrainGrow[l,y] + GrowBuy[y] - GrainSell[y];
  }
  //kacper
  forall(y in YearNbs) {
    countSugarBeetConsumption: CowTotal[y] * SugarbeetPerCow <= SugarbeetGrow[y] + SugarbeetBuy[y] - SugarbeetSell[y];
  }
  //mateusz
  forall(y in YearNbs) {
    countTotalAcreage: sum(l in LandNbs) 1.0/GrainPerAcre[l] * GrainGrow[l][y] 
       + 1.0/SugarbeetPerAcre * SugarbeetGrow[y] + HeifAcre * SmallCow[y]
       + HeifAcre * Cow[1][y] 
       + CowAcre * CowTotal[y] <= Acres; 
  }
  //hubert
  forall(y in YearNbs) {
    countTotalLabor: HeifLabor * SmallCow[y] + HeifLabor * Cow[1][y]
    + CowLabor * CowTotal[y]
    + GrainLabor * (sum(l in LandNbs) 1.0/GrainPerAcre[l] * GrainGrow[l][y])
    + SugarbeetLabor * 1.0 / SugarbeetPerAcre * SugarbeetGrow[y]
    <= Labor + LaborYear[y];
  }
  //kacper
  CountEndTotal: InitialCowsTotal * (1.0 - DownCowChange) <= CowTotal[Years] <= InitialCowsTotal * (1.0 + UpCowChange);

  // Profit - can't be less than 0
  //mateusz
  forall(y in YearNbs) {
    countTotalProfit: Profit[y] == BullockSellPrice * CalfRate * (1.0 - HeifFraction) * CowTotal[y] 
             + HeifSellPrice * HeifSell[y]
             + CowSellPrice * Cow[MaxAge][y]
             + MilkPerCowPrice * CowTotal[y] 
             + GrainSellPrice * GrainSell[y]
             + SugarbeetSellPrice * SugarbeetSell[y]
             - GrainBuyPrice * GrowBuy[y]
             - SugarbeetBuyPrice * SugarbeetBuy[y]
             - LaborCost * LaborYear[y]
             - LaborFixCost
             - HeifCost * SmallCow[y]
             - HeifCost * Cow[1][y]
             - CowCost * CowTotal[y] 
             - GrainGrowCost * (sum(l in LandNbs) 1.0/GrainPerAcre[l] * GrainGrow[l][y])
             - SugarbeetGrowCost * (1.0/SugarbeetPerAcre) * SugarbeetGrow[y]
             - Repay * (sum(k in YearNbs: k<=y) CapAdd[k]);
  }
}
