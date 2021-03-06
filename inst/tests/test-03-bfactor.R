context('bfactor')

test_that('dich data', {
    data <- key2binary(SAT12,
                       key = c(1,4,5,2,3,1,2,1,3,1,2,4,2,1,5,3,4,4,1,4,3,3,4,1,3,5,1,3,1,5,4,5))
    specific <- c(2,3,2,3,3,2,1,2,1,1,1,3,1,3,1,2,1,1,3,3,1,1,3,1,3,3,1,3,2,3,1,2)
    mod1 <- bfactor(data, specific, verbose=FALSE)    
    expect_is(mod1, 'ConfirmatoryClass')
    expect_equal(mod1@df, 501)
    cfs <- as.numeric(do.call(c, coef(mod1, digits=4)))
    cfs <- cfs[cfs != 0 & cfs != 1]
    expect_equal(cfs, c(0.7851, 0.4359, -1.0717, 1.4896, 0.8156, 0.4711, 1.1475, -0.1538, -1.1727, 0.5263, 0.5811, -0.5573, 0.9675, 0.5152, 0.6284, 1.1362, 0.5778, -2.1255, 1.0436, 0.9263, 1.5563, 0.6731, 0.5188, -1.5687, 0.454, 1.1078, 2.5243, 1.0477, 0.8195, -0.4047, 1.5918, 0.8204, 5.3883, 0.1207, 0.2754, -0.3506, 1.1001, 0.5778, 0.8844, 1.0876, 1.0359, 1.3602, 1.3332, 0.5342, 2.0112, 0.7362, 0.387, -0.3906, 1.5292, 0.2704, 4.1835, 1.758, 0.1904, -0.8748, 0.8626, 0.0379, 0.2387, 1.5305, 0.4172, 2.6498, 0.5334, 0.656, 2.6531, 1.6817, -0.0681, 3.6239, 0.6068, 0.4983, -0.8817, 1.2375, 0.2175, 1.2886, 0.7326, 0.6474, -0.5997, 1.4874, 0.4916, -0.1725, 1.9096, 0.4022, 2.807, 1.0559, 0.1523, 0.1725, 1.2574, 2.1318, -1.2135, 0.4331, -0.1688, -0.252, 2.5989, -0.2727, 3.0114, 0.1328, 0.028, -1.6521), 
                 tollerance = 1e-2)
    fs <- fscores(mod1, verbose = FALSE)
    expect_is(fs, 'matrix')        
    expect_true(mirt:::closeEnough(fs[1:6,'F1'] - c(-0.72059353, -0.07439544, -1.91235316,
                                                    -1.99421796, -2.00030284, -1.92556420), -1e-2, 1e-2))
    cof <- coef(mod1, verbose = FALSE)
    expect_is(cof, 'list')
    sum <- summary(mod1, verbose = FALSE)
    expect_is(sum, 'list')    
    pfit1 <- personfit(mod1)
    expect_is(pfit1, 'data.frame')    
    ifit <- itemfit(mod1)
    expect_is(ifit, 'data.frame')

    #simulate data
    set.seed(1234)
    a <- matrix(c(
        1,0.5,NA,
        1,0.5,NA,
        1,0.5,NA,
        1,0.5,NA,
        1,0.5,NA,
        1,0.5,NA,
        1,0.5,NA,
        1,NA,0.5,
        1,NA,0.5,
        1,NA,0.5,
        1,NA,0.5,
        1,NA,0.5,
        1,NA,0.5,
        1,NA,0.5),ncol=3,byrow=TRUE)
    
    d <- matrix(c(
        -1.0,NA,NA,
        -1.5,NA,NA,
        1.5,NA,NA,
        0.0,NA,NA,
        0.0,-1.0,1.5,
        0.0,2.0,-0.5,
        3.0,2.0,-0.5,
        3.0,2.0,-0.5,
        2.5,1.0,-1,
        2.0,0.0,NA,
        -1.0,NA,NA,
        -1.5,NA,NA,
        1.5,NA,NA,
        0.0,NA,NA),ncol=3,byrow=TRUE)
    
    nominal <- matrix(NA, nrow(d), ncol(d))
    nominal[5, ] <- c(0,1.2,2)    
    sigma <- diag(3)
    set.seed(1234)
    items <- itemtype <- c(rep('dich', 4), 'nominal', 'gpcm', rep('graded',4),rep('dich', 4))
    dataset <- simdata(a,d,3000,itemtype, sigma=sigma, nominal=nominal)  
     
    specific <- c(rep(1,7),rep(2,7))
    items[items == 'dich'] <- '2PL'
    simmod <- suppressMessages(bfactor(dataset, specific, itemtype = items, verbose=FALSE))    
    expect_is(simmod, 'ConfirmatoryClass')              
    expect_equal(simmod@df, 2442)
    cfs <- as.numeric(do.call(c, coef(simmod, digits=4)))
    cfs <- cfs[cfs != 0 & cfs != 1]
    expect_equal(cfs, c(1.1041, 0.08, -1.0015, 1.1639, -0.5017, -1.5207, 1.1132, 0.634, 1.6349, 0.9834, 0.0885, 0.0694, 1.1464, 0.2551, 1.1043, 2, -0.9361, 1.5983, 1.1543, -0.1421, 2.0817, -0.4029, 1.1246, 0.0932, 3.0943, 2.0269, -0.4557, 0.9981, 0.6139, 3.0811, 2.0627, -0.4541, 0.8432, 0.6361, 2.4515, 0.9724, -0.9835, 1.018, 0.5648, 2.0248, -0.0309, 0.8408, 0.7581, -1.0135, 0.9375, 0.5238, -1.3633, 0.8808, 0.4932, 1.5456, 0.951, 0.7649, 0.0282), 
                 tollerance = 1e-2)   
    specific[1] <- NA
    simmod2 <- suppressMessages(bfactor(dataset, specific, itemtype = items, verbose=FALSE))
    expect_is(simmod2, 'ConfirmatoryClass')              
    expect_equal(simmod2@df, 2443)
    cfs <- as.numeric(do.call(c, coef(simmod2, digits=4)))
    cfs <- cfs[cfs != 0 & cfs != 1]
    expect_equal(cfs, c(1.1073, -1.0015, 1.1533, -0.5015, -1.5162, 1.1238, 0.6408, 1.6411, 0.9848, 0.0714, 0.0694, 1.1502, 0.2444, 1.1029, 2, -0.9348, 1.5998, 1.1502, -0.1402, 2.0787, -0.4023, 1.1264, 0.0699, 3.0944, 2.027, -0.4557, 0.997, 0.6156, 3.0811, 2.0627, -0.454, 0.8424, 0.6371, 2.4515, 0.9724, -0.9835, 1.0168, 0.5667, 2.0248, -0.0308, 0.8398, 0.7591, -1.0135, 0.938, 0.5235, -1.3634, 0.8795, 0.4952, 1.5456, 0.9501, 0.7663, 0.0282),
                 tollerance = 1e-2)   
    fs <- fscores(simmod, verbose = FALSE)
    expect_true(mirt:::closeEnough(fs[1:6,'F1'] - c(-2.713717, -2.440282, -2.177029,
                                                    -2.265682, -2.249449, -2.416284), -1e-2, 1e-2))
    expect_is(fs, 'matrix')
    
    res <- residuals(simmod, verbose = FALSE)
    expect_is(res, 'matrix')
    fit <- fitted(simmod)
    expect_is(fit, 'matrix')  
    sum <- summary(simmod, verbose = FALSE)
    expect_is(sum, 'list')
})
