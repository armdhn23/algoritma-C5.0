library(C50)
library(caret)
library(plyr)

set.seed(11) #86

#### load data
Data1<-read.csv("data/coba13.csv", stringsAsFactors = T)
Data1<-Data1[-1]
str(Data1)


#### split data training dan testing
sampel<-sample(1:nrow(Data1),0.80*nrow(Data1),replace = FALSE)
training<-data.frame(Data1)[sampel,]
testing<-data.frame(Data1)[-sampel,] 


#### 10 folds cross validation
training <- training[sample(nrow(training)),] 
swasembada <- training[training$Klasifikasi.Desa == 'C', ] 
swakarya <- training[training$Klasifikasi.Desa == 'B', ] 
swadaya <- training[training$Klasifikasi.Desa == 'A', ] 

dataswasembada <- swasembada[sample(nrow(swasembada)),] 
foldsswasembada <- cut(seq(1,nrow(dataswasembada)), breaks = 10, labels = FALSE) 

dataswakarya <- swakarya[sample(nrow(swakarya)),] 
foldsswakarya <- cut(seq(1,nrow(dataswakarya)), breaks = 10, labels = FALSE) 

dataswadaya <- swadaya[sample(nrow(swadaya)),] 
foldsswadaya <- cut(seq(1,nrow(dataswadaya)), breaks = 10, labels = FALSE)

akurasi_folds <- vector(length = 10) 
akurasi_testing <- vector(length = 10) 
akurasi_data <- vector(length = 10) 


### membuat model
for(i in 1:10){
  indexswasembada <- which(foldsswasembada==i, arr.ind = TRUE)   
  indexswakarya <- which(foldsswakarya==i, arr.ind = TRUE)   
  indexswadaya <- which(foldsswadaya==i, arr.ind = TRUE)   
  testDataswasembada <- dataswasembada[indexswasembada, ]   
  trainDataswasembada <- dataswasembada[-indexswasembada, ]   
  testDataswakarya <- dataswakarya[indexswakarya, ]   
  trainDataswakarya <- dataswakarya[-indexswakarya, ]   
  testDataswadaya <- dataswadaya[indexswadaya, ]   
  trainDataswadaya <- dataswadaya[-indexswadaya, ] 
  testData <- join_all(list(testDataswadaya,testDataswakarya,testDataswasembada), type = 'full') 
  trainData <- join_all(list(trainDataswadaya,trainDataswakarya,trainDataswasembada), type = 'full')
  assign(paste0("dataTes",i), testData)
  assign(paste0("dataTrain",i), trainData)
  #model
  modelnya <- C5.0(Klasifikasi.Desa~., data=trainData)
  assign(paste0("Model",i), modelnya)
  #### data folds
  prediksinya <- (predict(modelnya, testData))
  temp <- table(prediksinya, testData$Klasifikasi.Desa)
  akurasi <- ((temp[1,1]+temp[2,2]+temp[3,3])/sum(temp))*100
  akurasi_folds[i] <- akurasi
  ##### data testing
  prediksinya1 <- predict(modelnya,testing)
  temp1 <- table(prediksinya1, testing$Klasifikasi.Desa)
  akurasitesting <- ((temp1[1,1]+temp1[2,2]+temp1[3,3])/sum(temp1))*100
  akurasi_testing[i] <- akurasitesting
  ##### data semua
  prediksinya2 <- predict(modelnya,Data1)
  temp2 <- table(prediksinya2, Data1$Klasifikasi.Desa)
  akurasidata <- ((temp2[1,1]+temp2[2,2]+temp2[3,3])/sum(temp2))*100
  akurasi_data[i] <- akurasidata
  #### confusion matrix
  assign(paste0("Hasil_folds",i), confusionMatrix(prediksinya, testData$Klasifikasi.Desa)) 
  assign(paste0("Hasil_testing",i), confusionMatrix(prediksinya1, testing$Klasifikasi.Desa)) 
  assign(paste0("Hasil_data",i), confusionMatrix(prediksinya2, Data1$Klasifikasi.Desa))
} 
##hasil
akurasi_folds
akurasi_testing
akurasi_data

### membuat ukuran pohon
ukuran_pohon<-c(Model1$size,Model2$size,Model3$size,Model4$size,Model5$size,Model6$size,Model7$size,
                Model8$size,Model9$size,Model10$size)

### membuat data frame akurasi
akurasi<-data.frame(akurasi_folds,akurasi_testing)

akurasi_rata <- dplyr::mutate(akurasi,rata_rata=((akurasi_folds+akurasi_testing)/2))
hasil<-data.frame(akurasi_rata,ukuran_pohon)
View(hasil)
