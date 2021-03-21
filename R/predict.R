require(plumber)

#* @apiTitle Prediction Survived

#* Return the prediction survived
#* @param sex Sex
#* @param pclass Pclass
#* @param age Age
#* @get /predict
function(sex, pclass, age) {
  
  load("R/plumber.RData")
  
  predict(cart0, newdata = data.frame(Sex = sex, Pclass = pclass, Age = as.numeric(age)))[2]
  
}
