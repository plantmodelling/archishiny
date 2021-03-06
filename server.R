
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)

shinyServer(
  function(input, output, clientData, session) {  
    
    rs <- reactiveValues(architect = NULL,
                         genotypes = NULL,
                         archi = NULL)
    
    
  # Load the dataset
  # observeEvent(input$load_data, {
    
    observe({
    
    # if(input$use_example){
      load("www/architect.RData")
      load("www/archi.RData")
      load("www/genotypes.RData")
      load("www/perh.RData")
      load("www/perh_summary.RData")
      load("www/archi_summary.RData")
      load("www/perhomology.RData")
      load("www/distances.RData")
      load("www/histogram.RData")
      rs$histogram <- histogram
      rs$architect <- architect
      rs$genotypes <- genotypes
      rs$archi <- archi
      rs$perh <- perh
      rs$distances <- distance
      rs$perh_summary <- perh_summary
      rs$archi_summary <- archi_summary
      rs$perhomology <- perhomology
      
      rs$names <- read_csv("www/names.csv")

      
      ## Preprocess the data manaully
      if(1==2){
          path <- "../rsmls/"
          architect <- architect(inputrsml=path, rsml.connect=T, rsml.date="age", fitter=T)
          genotypes <- unlist(lapply(strsplit(as.character(architect$FileName), "-"), `[[`, 1))[]
          architect$genotype <- genotypes
          save(architect, file="www/architect.RData")
          save(genotypes, file="www/genotypes.RData")
          
          archi <- rsmlToTable(path, fitter=T)
          genotypes <- unlist(lapply(strsplit(as.character(archi$file), "-"), `[[`, 1))[]
          rep <- unlist(lapply(strsplit(as.character(archi$file), "-"), `[[`, 3))[]
          archi$genotype <- genotypes
          archi$rep <- rep
          archi$age <- as.numeric(archi$time)
          save(archi, file="www/archi.RData")
      
          # Compute the angle data to make the histgram
          archi$rangle <- round(archi$orientation)
          hist1 <- ddply(archi, .(time, genotype, file, rep, root, rangle), summarize, n=ceiling(sum(length/10)))
          angle <- ddply(hist1,.(time, genotype, file, rep, root), summarize, value = rep(rangle,n))
          
          # Compute the diameter data to make the histgram
          archi$rdiam <- round(archi$diameter2)
          hist1 <- ddply(archi, .(time, genotype, file, rep, root, rdiam), summarize, n=ceiling(sum(length/10)))
          diameter <- ddply(hist1,.(time, genotype, file, rep, root), summarize, value = rep(rdiam,n))
          
          # Compute the growth data to make the histgram
          archi$rgrowth <- round(archi$growth)
          hist1 <- ddply(archi, .(time, genotype, file, rep, root, rgrowth), plyr::summarize, n=ceiling(sum(length/10)))
          growth <- ddply(hist1,.(time, genotype, file, rep, root), plyr::summarize, value = rep(rgrowth,n))

          # Compute the depth data to make the histgram
          archi$rdepth <- round(archi$y2)
          hist1 <- ddply(archi, .(time, genotype, file, rep, root, rdepth), plyr::summarize, n=ceiling(sum(length/10)))
          depth <- ddply(hist1,.(time, genotype, file, rep, root), plyr::summarize, value = rep(rdepth,n))        
            
          # Compute the geodesic data to make the histgram
          archi$rgeo <- round(archi$geodesic)
          hist1 <- ddply(archi, .(time, genotype, file, root, rep, rgeo), summarize, n=ceiling(sum(length/10)))
          geodesic <- ddply(hist1,.(time, genotype, file, rep, root), summarize, value = rep(rgeo,n)) 
          
          # Compute the magnitude data to make the histgram
          hist1 <- ddply(archi, .(time, genotype, file, root, rep, magnitude), summarize, n=ceiling(sum(length/10)))
          magnitude <- ddply(hist1,.(time, genotype, file, rep, root), summarize, value = rep(magnitude,n)) 
          
          # Compute the pathlength data to make the histgram
          hist1 <- ddply(archi, .(time, genotype, file, root, rep, pathlength), summarize, n=ceiling(sum(length/10)))
          pathlength <- ddply(hist1,.(time, genotype, file, rep, root), summarize, value = rep(pathlength,n)) 
          
          # Compute the length data to make the histgram
          length <- ddply(archi, .(file, plant, root, genotype), summarise, value=sum(length))
          
          histogram = list("angle"=angle, 
                           "diameter"=diameter, 
                           "growth"=growth, 
                           "length"=length,
                           "depth"=depth,
                           "geodesic"=geodesic,
                           "magnitude"=magnitude,
                           "pathlength"=pathlength)
          
          save(histogram, file="www/histogram.RData")
          
          
          ggplot(histogram$angle, aes(value, colour=genotype, group=file)) + 
            geom_density() +
            theme_classic() + 
            theme(legend.position = "null") + 
            facet_wrap(~genotype, ncol=3)
          
          ggplot(histogram, aes(angle, colour=genotype)) + 
            geom_density() +
            theme_classic()
          
          
          
          ggplot(root_data, aes(length, colour=genotype, group=file)) + 
            geom_density(alpha=0.5) + 
            theme_classic()
          
          ggplot(root_data, aes(length, colour=genotype)) + 
            geom_density()
          
          
          perhomology <- perhomology(archi, FUN="geodesic")
          perhomology2 <- perhomology(archi, FUN="depth")
          # perhomology3 <- perhomology(archi, FUN="magnitude")
          dist_1 <- bottleneckdist(perhomology)
          dist_2 <- bottleneckdist(perhomology2)
      
          distance <- sqrt(dist_1^2 + dist_2^2)
          distance <- as.data.frame(distance)
          distance$genotypes <- c(rep("dense", 10),rep("fast", 10),rep("mock", 10),rep("shallow", 10),rep("slow", 10),rep("sparse", 10),rep("steep", 10))
          save(distance, file="www/distances.RData")
      
          save(perhomology, file="www/perhomology.RData")
          names  <- names(perhomology)
          perh <- NULL
          for(i in c(1:length(perhomology))){
            temp <- data.frame(perhomology[[i]])
            temp$y <- c(1:nrow(temp))
            temp$type <- "geodesic"
            temp$file <- names[i]
            perh <- rbind(perh, temp)
          }
          for(i in c(1:length(perhomology2))){
            temp <- data.frame(perhomology2[[i]])
            temp$y <- c(1:nrow(temp))
            temp$type <- "depth"
            temp$file <- names[i]
            perh <- rbind(perh, temp)
          }
          genotypes <- unlist(lapply(strsplit(as.character(perh$file), "-"), `[[`, 1))[]
          rep <- unlist(lapply(strsplit(as.character(perh$file), "-"), `[[`, 3))[]
          perh$genotype <- genotypes
          perh$rep <- rep
          save(perh, file="www/perh.RData")
      
      
            # PCA(perh_PCA)
      
      
          #Compute new distance matrix
          # distance<-sqrt(dist_1^2+dist_2^2)

          pca <- prcomp(distance[,-ncol(distance)], retx = T, scale=T)  # Make the PCA
          genotypes <- unlist(lapply(strsplit(as.character(rownames(pca$rotation)), "-"), `[[`, 1))[]
          pca.results <- cbind(genotype=genotypes, data.frame(pca$x)[,])
      
          vars <- apply(pca$x, 2, var)
          props <- round((vars / sum(vars) * 100), 1)
          xl <- paste0("\nPrincipal Component 1 (",props[1],"%)")
          yl <-paste0("Principal Component 2 (",props[2],"%)\n")
      
          ggplot(data = pca.results) +
            geom_point(aes(PC1, PC2, colour=genotype)) +
            stat_ellipse(aes(PC1, PC2, colour=genotype), level = 0.9, size=1) +
            theme_bw() +
            xlab(xl) +
            ylab(yl)
      
          perh_summary <- ddply(perh, .(file, genotype, rep, type), summarise, sumdeath=sum(death),
                          sumbirth = sum(birth),
                          maxdeath = max(death),
                          maxbirth = max(birth),
                          ndeath = length(death),
                          nbirth = length(birth),
                          life = mean(birth-death))
          save(perh_summary, file="www/perh_summary.RData")
          
          archi_summary <- ddply(archi, .(file, genotype, rep), summarise, 
                                 n_root=length(x1),
                                 depth = max(y1),
                                 tot_length = sum(length),
                                 magnitude = max(magnitude),
                                 path_length = max(pathlength))
          save(archi_summary, file="www/archi_summary.RData")          

      }
      

  })
  
    
    observeEvent(input$load_code, {
      text <- 'library(archidart)

path <- "YOUR_PATH_TO_FOLDER"

architect <- architect(inputrsml=path, rsml.connect=F, rsml.date="age")\n

genotypes <- unlist(lapply(strsplit(as.character(architect$FileName), "-"), `[[`, 1))[]
architect$genotype <- genotypes
archi <- rsmlToTable(path)

genotypes <- unlist(lapply(strsplit(as.character(archi$plant), "-"), `[[`, 1))[]
rep <- unlist(lapply(strsplit(as.character(archi$plant), "-"), `[[`, 3))[]
archi$genotype <- genotypes
archi$rep <- rep
archi$age <- as.numeric(archi$age)'
      showModal(modalDialog(
        pre(text),
        easyClose = TRUE      
        ))
    })    

    
  ############################################################
  ### UI commands
  ############################################################
  
  # observe({
  #   if(is.null(rs$architect)){return()}
  #   vars <- colnames(rs$architect)[-c(1,2)]
  #   ct_options <- list()
  #   sel <- input$to_plot_1
  #   print(sel)
  #   for(ct in vars) ct_options[[ct]] <- ct
  #   if(length(sel) == 0 | sel == "") sel = ct_options[1]
  #   # cts  <- c("tot_root_length","n_laterals","tot_lat_length")
  #   updateSelectInput(session, "to_plot_1", choices = ct_options, selected=sel) 
  # }) 
  
  observe({
    if(is.null(rs$architect)){return()}
    vars <- rs$names$value#colnames(rs$architect)[-c(1,2,ncol(rs$architect))]
    ct_options <- list()
    sel <- input$to_plot
    for(ct in vars) ct_options[[ct]] <- ct
    if(length(sel) == 0 | sel == "") sel = ct_options[1]
    # cts  <- c("tot_root_length","n_laterals","tot_lat_length")
    updateSelectInput(session, "to_plot", choices = ct_options, selected=sel) 
  })
  
  observe({
    if(is.null(rs$perh_summary)){return()}
    vars <- colnames(rs$perh_summary)[-c(1:4)]
    ct_options <- list()
    sel <- input$to_plot_4
    for(ct in vars) ct_options[[ct]] <- ct
    if(length(sel) == 0 | sel == "") sel = ct_options[1]
    # cts  <- c("tot_root_length","n_laterals","tot_lat_length")
    updateSelectInput(session, "to_plot_4", choices = ct_options, selected=sel) 
  })
  
  observe({
    if(is.null(rs$archi_summary)){return()}
    vars <- colnames(rs$archi_summary)[-c(1:3)]
    ct_options <- list()
    sel <- input$to_plot_2_bis
    for(ct in vars) ct_options[[ct]] <- ct
    if(length(sel) == 0 | sel == "") sel = ct_options[1]
    # cts  <- c("tot_root_length","n_laterals","tot_lat_length")
    updateSelectInput(session, "to_plot_2_bis", choices = ct_options, selected=sel) 
  })  
  
  observe({
    if(is.null(rs$architect)){return()}
    vars <- unique(rs$architect$Time)
    sel <- input$time_to_plot
    if(length(sel) == 0 | sel == "") sel = vars[length(vars)]
    # cts  <- c("tot_root_length","n_laterals","tot_lat_length")
    updateSliderInput(session, "time_to_plot", min=min(vars), max=max(vars), step=1, value=sel) 
  })
  
  observe({
    if(is.null(rs$genotypes)){return()}
    vars <- unique(rs$genotypes)
    ct_options <- list()
    sel <- input$genotypes_to_plot
    if(length(sel) == 0) sel = vars
    for(ct in vars) ct_options[[ct]] <- ct
    # cts  <- c("tot_root_length","n_laterals","tot_lat_length")
    updateSelectInput(session, "genotypes_to_plot", choices = ct_options, selected=sel) 
  }) 
  
  observe({
    if(is.null(rs$genotypes)){return()}
    vars <- unique(rs$genotypes)
    ct_options <- list()
    sel <- input$genotypes_to_plot_1
    if(length(sel) == 0) sel = vars
    for(ct in vars) ct_options[[ct]] <- ct
    # cts  <- c("tot_root_length","n_laterals","tot_lat_length")
    updateSelectInput(session, "genotypes_to_plot_1", choices = ct_options, selected=sel) 
  }) 
  
  observe({
    if(is.null(rs$genotypes)){return()}
    vars <- unique(rs$genotypes)
    ct_options <- list()
    sel <- input$genotypes_to_plot_2
    if(length(sel) == 0) sel = vars
    for(ct in vars) ct_options[[ct]] <- ct
    # cts  <- c("tot_root_length","n_laterals","tot_lat_length")
    updateSelectInput(session, "genotypes_to_plot_2", choices = ct_options, selected=sel) 
  })   
  
  observe({
    if(is.null(rs$genotypes)){return()}
    vars <- unique(rs$genotypes)
    ct_options <- list()
    sel <- input$genotypes_to_plot_3
    if(length(sel) == 0) sel = vars
    for(ct in vars) ct_options[[ct]] <- ct
    # cts  <- c("tot_root_length","n_laterals","tot_lat_length")
    updateSelectInput(session, "genotypes_to_plot_3", choices = ct_options, selected=sel) 
  })     
  
  observe({
    if(is.null(rs$architect)){return()}
    vars <- rs$names$value#colnames(rs$architect)[-c(1,2,ncol(rs$architect))]
    ct_options <- list()
    sel <- input$variable_to_pca
    for(ct in vars) ct_options[[ct]] <- ct
    if(is.null(sel)) sel = ct_options
    if(length(sel) == 0 | sel == "") sel = ct_options
    # cts  <- c("tot_root_length","n_laterals","tot_lat_length")
    updateSelectInput(session, "variable_to_pca", choices = ct_options, selected=sel) 
  }) 
  
  ############################################################
  ### PLOTS
  ############################################################
  
  # Variable distribution
  # output$distribution_plot <- renderPlot({
  #   if(is.null(rs$architect)){return()}
  #   
  #   temp <- rs$architect
  #   temp$value <- temp[[input$to_plot_1]]
  #   
  #   pl <- ggplot(temp, aes(value)) + 
  #     geom_density(col="gray", fill="gray", alpha=0.5) + 
  #     ylab("") + 
  #     xlab(input$to_plot_1) + 
  #     ggtitle(input$to_plot_1) + 
  #     theme_classic() +
  #     theme(axis.text.x = element_text(angle = 45, hjust = 1), text=element_text(size=15))
  #   pl
  #   
  # }) 

  
  # Time plot
  
  output$time_plot <- renderPlot({
    if(is.null(rs$architect)){return()}
    val <- rs$names$name[rs$names$value == input$to_plot]
    temp <- rs$architect[rs$architect$genotype %in% input$genotypes_to_plot,]
    temp$value <- temp[[val]]
    
    pl <- ggplot(temp) +  
      xlab("Time [days]") + 
      ylab(input$to_plot) + 
      ggtitle(input$to_plot) + 
      theme_classic() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1), text=element_text(size=15))
    
    if(input$plot_mean){
      pl <- pl+ stat_smooth(aes(Time, value, colour=genotype)) 
    } else{
      pl <- pl + geom_line(aes(Time, value, colour=genotype, group=FileName))
    }
    
    pl
    
  }) 
  
  
  observeEvent(input$time_code, {
    text <- paste0('library(ggplot2)
ggplot(data = architect) +  
                   xlab("Time [days]") + 
                   ylab("',input$to_plot,'") + 
                   ggtitle("',input$to_plot,'") + 
                   theme_classic() +
                   ')    
    
    if(input$plot_mean){
      text <- paste0(text, 'stat_smooth(aes(Time,',input$to_plot,', colour = genotype))')
    }else{
      text <- paste0(text, 'geom_line(aes(Time,',input$to_plot,', colour = genotype, group = FileName))')
    }
    
    showModal(modalDialog(
      pre(text),
      easyClose = TRUE      
    ))
  })   
  
  
  
  # archi plot
  output$archi_plot <- renderPlot({
    if(is.null(rs$archi)){return()}
    
    temp <- rs$archi[rs$archi$genotype %in% input$genotypes_to_plot_1,]
    temp <- temp[as.numeric(temp$rep) <= input$reps_to_plot,]
    temp$value <- temp[[input$to_plot_2]]
    # 
    # temp <- archi %>%
    #   filter(rep < 4)
    # temp$value <- temp$geodesic
    # 
    # ggplot(temp) + 
    #   geom_segment(aes(x = x1, y = -y1, xend = x2, yend = -y2, colour=value), size=0.5, alpha=0.8) + 
    #   coord_fixed() + 
    #   theme_bw() + 
    #   scale_colour_gradientn(colours=cscale3)+
    #   #scale_colour_gradientn(colours = terrain.colors(10)) + 
    #   facet_wrap(~genotype, ncol=3)
    
    
    if(!input$plot_mean_archi){
      pl <- ggplot(temp) + 
          geom_segment(aes(x = x1, y = -y1, xend = x2, yend = -y2, colour=value), size=input$linesize) + 
          coord_fixed() + 
          theme_bw() + 
          scale_colour_gradientn(colours=cscale3,
                               limits = input$psirange) + 
          facet_wrap(~file, ncol=input$ncol)  +
        theme(legend.position="bottom")
         
    }else{
      pl <- ggplot(temp) + 
        geom_segment(aes(x = x1, y = -y1, xend = x2, yend = -y2, colour=value), size=input$linesize, alpha=0.8) + 
        coord_fixed() + 
        theme_bw() + 
        scale_colour_gradientn(colours=cscale3,
                               limits = input$psirange)+
        #scale_colour_gradientn(colours = terrain.colors(10)) + 
        facet_wrap(~genotype, ncol=input$ncol) +
        theme(legend.position="top")
    }
    
    pl
  })
  
  observeEvent(input$archi_code, {
    if(!input$plot_mean_archi){
    
      text <- paste0('library(ggplot2)
ggplot(data = archi) +  
  geom_segment(aes(x = x1, y = -y1, xend = x2, yend = -y2, colour = ',input$to_plot_2,')) + 
  coord_fixed() + 
  theme_bw() + 
  facet_wrap(~plant, ncol=',input$ncol,') +
  theme_classic()')    
  }else{
    text <- paste0('library(ggplot2)
ggplot(archi) + 
  geom_segment(aes(x = x1, y = -y1, xend = x2, yend = -y2, colour = ',input$to_plot_2,'), size = 0.5, alpha = 0.5) + 
  coord_fixed() + 
  theme_bw() + 
  facet_wrap(~genotype, ncol=',input$ncol,')')
  }
    showModal(modalDialog(
      pre(text),
      easyClose = TRUE
    ))
  })
  
  
  
  output$distri_plot <- renderPlot({
    if(is.null(rs$archi)){return()}
    
    temp <- rs$histogram[[input$to_plot_distri]] %>%
      filter(genotype %in% input$genotypes_to_plot_1) %>%
      filter(as.numeric(rep) <= input$reps_to_plot)

    if(input$plot_mean_archi){
      pl <- ggplot(temp, aes(x=value, colour=genotype, group=file)) + 
        geom_density() +
        theme_classic() + 
        theme(legend.position = "null") + 
        facet_wrap(~genotype, ncol=input$ncol)      
    }else{
      pl <- ggplot(temp, aes(x=value, colour=genotype)) + 
        geom_density() +
        theme_classic()
    }
    
    pl
  })
  
  observeEvent(input$distri_code, {
    var <- input$to_plot_distri
    if(var == "depth") var <- "y2"
    text <- paste0('library(ggplot2)
library(plyr)
# Compute the magnitude data to make the histgram
histogram <- archi %>% 
  mutate(value = round(',var,')) %>%
  ddply(.(time, genotype, file, rep, root, rdepth), plyr::summarize, n=ceiling(sum(length/10))) %>%
  ddply(.(time, genotype, file, rep, root), plyr::summarize, value = rep(rdepth,n)) %>%
  filter(genotype %in% ',input$genotypes_to_plot_1,') %>%
  filter(as.numeric(rep) <= ',input$reps_to_plot,')')

    if(input$plot_mean_archi){
      text <- paste0(text, '
pl <- ggplot(histogram, aes(x=value, colour=genotype, group=file)) + 
        geom_density() +
        theme_classic() + 
        theme(legend.position = "null") + 
        facet_wrap(~genotype, ncol=',input$ncol,')')      
    }else{
      text <- paste0(text, "
pl <- ggplot(histogram, aes(x=value, colour=genotype)) + 
        geom_density() +
        theme_classic()")
    }
    showModal(modalDialog(
      pre(text),
      easyClose = TRUE      
    ))
  })  
  
  
  output$archi_boxplot <- renderPlot({
    if(is.null(rs$perh_summary)){return()}
    
    temp <- rs$archi_summary %>%
      filter(genotype %in% input$genotypes_to_plot_1)
    
    temp$value <- temp[[input$to_plot_2_bis]]
    
    pl <- ggplot(temp, aes(genotype, value, fill=genotype)) + 
      geom_boxplot() + 
      theme_classic() +
      theme(legend.position = "none",
            text=element_text(size=15),
            axis.text.x = element_text(angle = 45, hjust = 1))+
      ylab(input$to_plot_2_bis) + 
      xlab("Genotype")
    
    
    pl
  })  
  
  observeEvent(input$boxplot_archi_code, {
    text <- paste0('library(plyr)
library(tidyverse)
                   
archi_summary <- ddply(archi, .(file, genotype, rep, type), summarise, 
                   n_root=length(x1),
                   depth = max(y1),
                   tot_length = sum(length),
                   magnitude = max(magnitude),
                   path_length = max(pathlength))
                   
archi_summary$value <- temp[["',input$to_plot_2_bis,'"]]
                   
pl <- ggplot(archi_summary, aes(genotype, value, fill=genotype)) + 
          geom_boxplot() + 
          theme_classic() +
          theme(legend.position = "none",
          text=element_text(size=15),
          axis.text.x = element_text(angle = 45, hjust = 1))+
          ylab(',input$to_plot_2_bis,') + 
          xlab("Genotype")'
    )
    showModal(modalDialog(
      pre(text),
      easyClose = TRUE      
    ))
  })  
  
  
  


  # archi plot
  output$barcode_plot <- renderPlot({
    if(is.null(rs$perh)){return()}
    
    temp <- rs$perh[rs$perh$genotype %in% input$genotypes_to_plot_2,]
    temp <- temp[temp$type == input$to_plot_3,]
    temp <- temp[as.numeric(temp$rep) <= input$reps_to_plot_2,]

    alph <- 1/input$reps_to_plot_2
    
    pl <- ggplot(temp) + 
      geom_segment(aes(x = birth, y=y, xend=death, yend=y, alpha=alph, colour=rep)) + 
      facet_wrap(~genotype) + 
      theme_classic() +
      theme(legend.position = "none")+
      ylab("H0") + 
      xlab("Geodesic distance (cm)")
    
    
    pl
  })
  
  
  observeEvent(input$barcode_code, {
    
    text <- paste0('
library(tidyverse)

# Compile the data in a table
 perhomology <- perhomology(archi, FUN="',input$to_plot_3,'")
 names  <- names(perhomology)
 perh <- NULL
 for(i in c(1:length(perhomology))){
   temp <- data.frame(perhomology[[i]])
   temp$y <- c(1:nrow(temp))
   temp$file <- names[i]
   perh <- rbind(perh, temp)
 }
 genotypes <- unlist(lapply(strsplit(as.character(perh$file), "-"), `[[`, 1))[]
 rep <- unlist(lapply(strsplit(as.character(perh$file), "-"), `[[`, 3))[]
 perh$genotype <- genotypes
 perh$rep <- rep
 
 ggplot(perh) + 
   geom_segment(aes(x = birth, y=y, xend=death, yend=y, alpha=0.1)) + 
   facet_wrap(~genotype) + 
   theme_classic() +
   theme(legend.position = "none")+
   ylab("H0") + 
   xlab("',input$to_plot_3,' distance (cm)")')
    
  showModal(modalDialog(
    pre(text),
    easyClose = TRUE      
  ))
  })  
  
  
  
  output$barcode_boxplot <- renderPlot({
    if(is.null(rs$perh_summary)){return()}
    
    temp <- rs$perh_summary[rs$perh_summary$genotype %in% input$genotypes_to_plot_2,]
    temp <- temp[temp$type == input$to_plot_3,]
    
    temp$value <- temp[[input$to_plot_4]]

    pl <- ggplot(temp, aes(genotype, value, fill=genotype)) + 
      geom_boxplot() + 
      theme_classic() +
      theme(legend.position = "none",
            text=element_text(size=15),
            axis.text.x = element_text(angle = 45, hjust = 1))+
      ylab(input$to_plot_4) + 
      xlab("Genotype")
    
    
    pl
  })  
  
  observeEvent(input$boxcode_code, {
    text <- paste0('    
library(plyr)
library(tidyverse)

perh_summary <- ddply(perh, .(file, genotype, rep, type), summarise, sumdeath=sum(death),sumbirth = sum(birth),maxdeath = max(death),maxbirth = max(birth),ndeath = length(death),nbirth = length(birth),life = mean(birth-death))

temp <- temp[temp$type == "',input$to_plot_3,'",]
           
temp$value <- temp[["',input$to_plot_4,'"]]
           
pl <- ggplot(temp, aes(genotype, value, fill=genotype)) + 
           geom_boxplot() + 
           theme_classic() +
           theme(legend.position = "none",
           text=element_text(size=15),
           axis.text.x = element_text(angle = 45, hjust = 1))+
           ylab(',input$to_plot_4,') + 
           xlab("Genotype")'
  )
  showModal(modalDialog(
    pre(text),
    easyClose = TRUE      
  ))
  })  
  
  
  
  
  
  output$barcode_PCA <- renderPlot({
    if(is.null(rs$distances)){return()}
    
    distance<-as.data.frame(rs$distances[rs$distances$genotype %in% input$genotypes_to_plot_2,])
    genotype <- distance$genotype
    
    mds <- metaMDS(as.dist(distance[,-(length(distance))]), trymax=200, autotransform=FALSE, wascores = FALSE, noshare=FALSE, expand=FALSE)
    data <- data.frame(mds$points, genotype=genotype)    

    pl <- ggplot(data) +
      geom_point(aes(MDS1, MDS2, colour=genotype)) +
      stat_ellipse(aes(MDS1, MDS2, colour=genotype), level = 0.9, size=1) +
      theme_bw() +
      xlab("NMDS-1") +
      ylab("NMDS-2")
    
    pl
  })
  
  
  
  observeEvent(input$barcode_PCA_code, {
    text <- paste0('library(tidyverse)
library(vegan)

perhomology_1 <- perhomology(archi, FUN="geodesic")
perhomology_2 <- perhomology(archi, FUN="depth")

dist_1 <- bottleneckdist(perhomology_1)
dist_2 <- bottleneckdist(perhomology_2)
 
distance <- sqrt(dist_1^2 + dist_2^2)
distance <- as.data.frame(distance)

mds <- metaMDS(as.dist(distance[,-(length(distance))]), trymax=200, autotransform=FALSE, wascores = FALSE, noshare=FALSE, expand=FALSE)
genotypes <- c(rep("dense", 10),rep("fast", 10),rep("mock", 10),rep("shallow", 10),rep("slow", 10),rep("sparse", 10),rep("steep", 10))
data <- data.frame(mds$points, genotype=genotypes)    
                   

ggplot(data) +
      geom_point(aes(MDS1, MDS2, colour=genotype)) +
      stat_ellipse(aes(MDS1, MDS2, colour=genotype), level = 0.9, size=1) +
      theme_bw() +
      xlab("NMDS-1") +
      ylab("NMDS-2")
')
    showModal(modalDialog(
      pre(text),
      easyClose = TRUE      
    ))
  }) 
  
  
  
  # PCA plot
  
  
  output$pca_plot <- renderPlot({
    if(is.null(rs$architect)){return()}
    
    temp <- rs$architect[rs$architect$genotype %in% input$genotypes_to_plot_3,]
    temp <- temp[temp$Time == input$time_to_plot,]
    plants <- temp$FileName
    genotypes <- temp$genotype
    vars <- rs$names$name[rs$names$value %in% input$variable_to_pca]
    temp <- temp[,vars]
    remove <- NULL
    for(i in c(1:ncol(temp))){
      if(sd(temp[,i]) == 0) remove <- c(remove,i)
    }
    
    if(!is.null(remove)) temp <- temp[,-remove]
    pca <- prcomp(temp, retx = T, scale=T)  # Make the PCA
    pca.results <- cbind(plant=plants, genotype=genotypes, data.frame(pca$x)[,])
    
    vars <- apply(pca$x, 2, var)  
    props <- round((vars / sum(vars) * 100), 1)
    xl <- paste0("\nPrincipal Component 1 (",props[1],"%)")
    yl <-paste0("Principal Component 2 (",props[2],"%)\n")
    
    pl1 <- ggplot(data = pca.results) + 
      geom_point(aes(PC1, PC2, colour=genotype)) +
      stat_ellipse(aes(PC1, PC2, colour=genotype), level = 0.9, size=1) + 
      theme_bw() + 
      xlab(xl) + 
      ylab(yl)
    
    z2 <- data.frame(var_names = rownames(pca$rotation), pca$rotation[, 1:2])
    z2$var_names <- gsub("_", " ", z2$var_names)
    
    pl2 <- ggplot(data=z2, aes(0, 0, xend=PC1, yend=PC2)) + 
      geom_segment(col="grey", size=1.2, arrow = arrow(length = unit(0.5,"cm")), alpha=0.9) +
      geom_text_repel(data=z2, aes(PC1, PC2, label=var_names), col="black", size=9) +
      geom_point(aes(x=0, y=0), colour="grey") +
      #scale_y_continuous(limits = c(-1, 0.3)) +
      theme_classic() +
      xlab(xl) + ylab(yl)

    pl <- grid.arrange(pl1, pl2, ncol=1)
      
  })
  
  
  observeEvent(input$pca_code, {
    vars <- paste(input$variable_to_pca,collapse=",")
    text <- paste0(
'library(gridExtra)
library(ggrepel)
library(ggplot2)

# Do the PCA analysis
plants <- rs$architect$FileName
genotypes <- rs$architect$genotype
temp <- rs$architect[,c(',vars,')]
pca <- prcomp(temp, retx = T, scale=T)  # Make the PCA
pca.results <- cbind(plant=plants, genotype=genotypes, data.frame(pca$x)[,])
    
vars <- apply(pca$x, 2, var)  
props <- round((vars / sum(vars) * 100), 1)
xl <- paste0("\nPrincipal Component 1 (",props[1],"%)")
yl <-paste0("Principal Component 2 (",props[2],"%)\n")

pl1 <- ggplot(data = pca.results) + 
  geom_point(aes(PC1, PC2, colour=genotype)) +
  stat_ellipse(aes(PC1, PC2, colour=genotype), level = 0.9, size=1) + 
  theme_bw() + 
  xlab(xl) + 
  ylab(yl)

z2 <- data.frame(var_names = rownames(pca$rotation), pca$rotation[, 1:2])
z2$var_names <- gsub("_", " ", z2$var_names)

pl2 <- ggplot(data=z2, aes(0, 0, xend=PC1, yend=PC2)) + 
  geom_segment(col="grey", size=1.2, arrow = arrow(length = unit(0.5,"cm")), alpha=0.9) +
  geom_text_repel(data=z2, aes(PC1, PC2, label=var_names), col="black", size=9) +
  geom_point(aes(x=0, y=0), colour="grey") +
  #scale_y_continuous(limits = c(-1, 0.3)) +
  theme_classic() +
  xlab(xl) + ylab(yl)

pl <- grid.arrange(pl1, pl2, ncol=1)' 
)
    showModal(modalDialog(
      pre(text),
      easyClose = TRUE      
    ))
  }) 
  
  ############################################################
  ### TABLE
  ############################################################  

  output$distribution_data <- DT::renderDataTable({
    if(is.null(rs$architect)){return()}
    DT::datatable(rs$architect, options = list(scrollX = TRUE, pageLength = 5))
  })
  
  
})
