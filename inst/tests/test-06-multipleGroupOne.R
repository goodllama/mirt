context('multipleGroupOne')

test_that('one factor', {    
    set.seed(12345)
    a <- matrix(abs(rnorm(15,1,.3)), ncol=1)
    d <- matrix(rnorm(15,0,.7),ncol=1)    
    itemtype <- rep('dich', nrow(a))
    N <- 1000    
    dataset1 <- simdata(a, d, N, itemtype)
    dataset2 <- simdata(a, d, N, itemtype, mu = .1, sigma = matrix(1.5))
    dat <- rbind(dataset1, dataset2)
    group <- c(rep('D1', N), rep('D2', N))    
    MGmodel1 <- 'F1 = 1-15'    
    models <- mirt.model(MGmodel1, quiet = TRUE)
    
    mod_configural <- multipleGroup(dat, models, group = group, verbose = FALSE, method = 'EM')
    expect_is(mod_configural, 'MultipleGroupClass')
    cfs <- as.numeric(do.call(c, coef(mod_configural, digits=4)[[1L]]))
    cfs <- cfs[cfs != 0 & cfs != 1]    
    expect_equal(cfs, c(1.0693, 0.5539, 1.278, -0.6919, 0.8833, -0.1376, 1.1112, 0.8293, 1.2481, 0.3263, 0.476, 0.4796, 1.1617, 1.0846, 0.8586, -0.3854, 0.89, -1.0482, 0.8085, -1.0909, 0.9013, 1.164, 1.5832, -0.1352, 1.4098, 0.654, 1.0401, 0.4071, 0.8804, -0.0813),
                 tollerance = 1e-2)
    expect_equal(mod_configural@df, 1621)
    mod_metric <- multipleGroup(dat, models, group = group, invariance=c('slopes'), verbose = FALSE, 
                                method = 'EM')
    expect_is(mod_metric, 'MultipleGroupClass')
    expect_equal(mod_metric@df, 1636)
    mod_scalar2 <- multipleGroup(dat, models, group = group, verbose = FALSE, method = 'EM',
                                 invariance=c('slopes', 'intercepts', 'free_varcov','free_means'))
    cfs <- as.numeric(do.call(c, coef(mod_scalar2, digits=4)[[1L]]))
    cfs <- cfs[cfs != 0 & cfs != 1]    
    expect_equal(cfs, c(1.1424, 0.562, 1.3256, -0.6511, 0.9936, -0.2011, 1.0489, 0.8864, 1.1449, 0.338, 0.4314, 0.4964, 1.2258, 1.1577, 0.916, -0.4199, 0.8163, -1.0167, 0.801, -1.089, 0.9487, 1.2346, 1.5886, -0.1897, 1.1991, 0.5384, 1.1292, 0.4326, 0.8934, -0.1172),
                 tollerance = 1e-2)
    expect_is(mod_scalar2, 'MultipleGroupClass')
    expect_equal(mod_scalar2@df, 1649)
    mod_scalar1 <- multipleGroup(dat, models, group = group, verbose = FALSE, method = 'MHRM',
                                 invariance=c('slopes', 'intercepts', 'free_varcov'), draws = 10)    
    expect_is(mod_scalar1, 'MultipleGroupClass')    
    dat[1,1] <- dat[2,2] <- NA
    mod_missing <- multipleGroup(dat, models, group = group, verbose = FALSE, method = 'EM',
                                 invariance=c('slopes', 'intercepts', 'free_varcov'))    
    expect_is(mod_missing, 'MultipleGroupClass')
    expect_equal(mod_missing@df, 1651)
    
    fs1 <- fscores(mod_metric, verbose = FALSE)
    expect_true(mirt:::closeEnough(fs1[[1]][1:6, 'F1'] - c(-2.084760, -1.683841, -1.412181,
                                                           -1.656879, -1.324689, -1.092169), -1e-2, 1e-2))    
    fs2 <- fscores(mod_metric, full.scores = TRUE)
    fs3 <- fscores(mod_missing, verbose = FALSE)
    fs4 <- fscores(mod_missing, full.scores = TRUE)
    fs5 <- fscores(mod_metric, full.scores = TRUE, scores.only=TRUE)
    expect_is(fs1, 'list')
    expect_is(fs2, 'data.frame')
    expect_is(fs3, 'list')
    expect_is(fs4, 'data.frame') 
    
    fit1 <- fitIndices(mod_metric)
    expect_is(fit1, 'data.frame')
    expect_true(mirt:::closeEnough(fit1[1:2] - c(1126.808, 2163.069), -1e-2, 1e-2))
    expect_true(mirt:::closeEnough(fit1$df.M2 - 350, -1e-4, 1e-4))    
    fit2 <- itemfit(mod_metric)
    expect_is(fit2, 'list')

    #missing data
    set.seed(1234)
    Theta1 <- rnorm(1000, -1)
    Theta2 <- rnorm(1000, 1) 
    Theta <- matrix(rbind(Theta1, Theta2))
    d <- rnorm(10,4)
    d <- cbind(d, d-1, d-2, d-3, d-4, d-5, d-6)
    a <- matrix(rlnorm(10, meanlog=.1))
    group <- factor(c(rep('g1',1000), rep('g2',1000)))
    
    dat <- simdata(a,d,2000, itemtype = rep('graded', 10), Theta=Theta)
    x <- multipleGroup(dat, 1, group=group, method='EM', verbose = FALSE)
    expect_is(x, 'MultipleGroupClass')
    
    dat[1,1] <- dat[2,2] <- NA
    x2 <- multipleGroup(dat, 1, group=group, method='EM', verbose = FALSE)
    expect_is(x2, 'MultipleGroupClass')
    cfs <- as.numeric(do.call(c, coef(x2, digits = 5)[[1L]]))
    cfs <- cfs[cfs != 0 & cfs != 1]    
    expect_true(mirt:::closeEnough(cfs - c(0.67631, 2.8773, 1.89605, 0.98807, 0.11831, -0.9515, -2.02503, -3.14965, 0.61578, 3.97403, 2.86755, 1.70175, 0.77828, -0.11123, -1.06288, -2.1234, 2.11944, 4.00951, 2.92423, 1.87607, 0.91273, -0.14699, -1.11217, -2.06626, 2.75331, 5.35612, 4.40304, 3.27763, 2.37802, 1.26594, 0.28548, -0.83408, 0.4657, 2.40553, 1.42492, 0.45785, -0.5893, -1.63296, -2.68958, -3.6855, 4.89347, 3.06574, 2.02968, 1.11669, 0.07604, -0.89326, -1.84402, -3.07211, 2.49513, 2.33565, 1.28172, 0.41657, -0.5044, -1.5002, -2.52619, -3.64079, 1.96502, 4.43456, 3.47399, 2.44497, 1.45493, 0.51981, -0.3822, -1.43513, 2.03149, 3.43966, 2.69065, 1.596, 0.66413, -0.41915, -1.4248, -2.3404, 2.35338, 2.26768, 1.25377, 0.37992, -0.64839, -1.80941, -2.80426, -3.87603), -1e-2, 1e-2))
    
})
