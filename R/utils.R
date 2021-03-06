# theta combinations
thetaComb <- function(theta, nfact)
{
	if (nfact == 1L){
        Theta <- matrix(theta)
	} else {
        thetalist <- vector('list', nfact)
        for(i in 1L:nfact)
            thetalist[[i]] <- theta
        Theta <- as.matrix(expand.grid(thetalist))
    }	
	return(Theta)
}

# Product terms 
prodterms <- function(theta0, prodlist)
{
    products <- matrix(1, ncol = length(prodlist), nrow = nrow(theta0))
    for(i in 1L:length(prodlist)){
        tmp <- prodlist[[i]]
        for(j in 1L:length(tmp))
            products[ ,i] <- products[ ,i] * theta0[ ,tmp[j]]
    }
    ret <- cbind(theta0,products)
    ret
}

# MH sampler for theta values
draw.thetas <- function(theta0, pars, fulldata, itemloc, cand.t.var, prior.t.var,
                        prior.mu, prodlist, OffTerm, NO.CUSTOM=FALSE)
{
    N <- nrow(fulldata)
    J <- length(pars) - 1L
    unif <- runif(N)
    sigma <- if(ncol(theta0) == 1L) matrix(cand.t.var) else diag(rep(cand.t.var,ncol(theta0)))
    theta1 <- theta0 + mvtnorm::rmvnorm(N,prior.mu, sigma)
    log_den0 <- mvtnorm::dmvnorm(theta0,prior.mu,prior.t.var,log=TRUE)
    log_den1 <- mvtnorm::dmvnorm(theta1,prior.mu,prior.t.var,log=TRUE)
    if(length(prodlist) > 0L){
        theta0 <- prodterms(theta0,prodlist)
        theta1 <- prodterms(theta1,prodlist)
    }
    itemtrace0 <- computeItemtrace(pars=pars, Theta=theta0, itemloc=itemloc, 
                                   offterm=OffTerm, NO.CUSTOM=NO.CUSTOM)
    itemtrace1 <- computeItemtrace(pars=pars, Theta=theta1, itemloc=itemloc, 
                                   offterm=OffTerm, NO.CUSTOM=NO.CUSTOM)    
    totals <- .Call('denRowSums', fulldata, itemtrace0, itemtrace1, log_den0, log_den1)    
    total_0 <- totals[[1L]] 
    total_1 <- totals[[2L]] 
    diff <- total_1 - total_0
    accept <- diff > 0
    accept[unif < exp(diff)] <- TRUE
    theta1[!accept, ] <- theta0[!accept, ]
    total_1[!accept] <- total_0[!accept]
    log.lik <- sum(total_1)
    if(!is.null(prodlist))
        theta1 <- theta1[ ,1L:(pars[[1L]]@nfact - pars[[1L]]@nfixedeffects -
                                  length(prodlist)), drop=FALSE]
    attr(theta1, "Proportion Accepted") <- sum(accept)/N
    attr(theta1, "log.lik") <- log.lik
    return(theta1)
}

# Rotation function
Rotate <- function(F, rotate, Target = NULL, ...)
{
    if(ncol(F) == 1L) rotF <- list()
    if(rotate == 'none') rotF <- list(loadings=F, Phi=diag(ncol(F)), orthogonal=TRUE)
	if(rotate == 'promax'){
        mypromax <- function (x, m = 4) {
                #borrowed and modified from stats::promax on Febuary 13, 2013
                if (ncol(x) < 2L)
                    return(x)
                dn <- dimnames(x)
                xx <- varimax(x)
                x <- xx$loadings
                Q <- x * abs(x)^(m - 1)
                U <- lm.fit(x, Q)$coefficients
                d <- diag(solve(t(U) %*% U))
                U <- U %*% diag(sqrt(d))
                dimnames(U) <- NULL
                z <- x %*% U
                U <- xx$rotmat %*% U
                ui <- solve(U)
                Phi <- ui %*% t(ui)
                dimnames(z) <- dn
                class(z) <- "loadings"
                list(loadings = z, rotmat = U, Phi = Phi, orthogonal = FALSE)
            }
        rotF <- mypromax(F, ...)
	}
    if(rotate == 'oblimin') rotF <- GPArotation::oblimin(F, ...)
	if(rotate == 'quartimin') rotF <- GPArotation::quartimin(F, ...)
	if(rotate == 'targetT') rotF <- GPArotation::targetT(F, Target = Target, ...)
	if(rotate == 'targetQ') rotF <- GPArotation::targetQ(F, Target = Target, ...)
	if(rotate == 'pstT') rotF <- GPArotation::pstT(F, Target = Target, ...)
	if(rotate == 'pstQ') rotF <- GPArotation::pstQ(F, Target = Target, ...)
	if(rotate == 'oblimax') rotF <- GPArotation::oblimax(F, ...)
	if(rotate == 'entropy') rotF <- GPArotation::entropy(F, ...)
	if(rotate == 'quartimax') rotF <- GPArotation::quartimax(F, ...)
	if(rotate == 'varimax') rotF <- GPArotation::Varimax(F, ...)
	if(rotate == 'simplimax') rotF <- GPArotation::simplimax(F, ...)
	if(rotate == 'bentlerT') rotF <- GPArotation::bentlerT(F, ...)
	if(rotate == 'bentlerQ') rotF <- GPArotation::bentlerQ(F, ...)
	if(rotate == 'tandemI') rotF <- GPArotation::tandemI(F, ...)
	if(rotate == 'tandemII') rotF <- GPArotation::tandemII(F, ...)
	if(rotate == 'geominT') rotF <- GPArotation::geominT(F, ...)
	if(rotate == 'geominQ') rotF <- GPArotation::geominQ(F, ...)
	if(rotate == 'cfT') rotF <- GPArotation::cfT(F, ...)
	if(rotate == 'cfQ') rotF <- GPArotation::cfQ(F, ...)
	if(rotate == 'infomaxT') rotF <- GPArotation::infomaxT(F, ...)
	if(rotate == 'infomaxQ') rotF <- GPArotation::infomaxQ(F, ...)
	if(rotate == 'mccammon') rotF <- GPArotation::mccammon(F, ...)
	if(rotate == 'bifactorT') rotF <- GPArotation::bifactorT(F, ...)
	if(rotate == 'bifactorQ') rotF <- GPArotation::bifactorQ(F, ...)
	return(unclass(rotF))
}

# Gamma correlation, mainly for obtaining a sign
gamma.cor <- function(x)
{
	concordant <- function(x){
			mat.lr <- function(r, c){
				lr <- x[(r.x > r) & (c.x > c)]
				sum(lr)
			}
		r.x <- row(x)
		c.x <- col(x)
		sum(x * mapply(mat.lr, r = r.x, c = c.x))
	}
	discordant <- function(x){
		mat.ll <- function(r, c){
			ll <- x[(r.x > r) & (c.x < c)]
			sum(ll)
		}
		r.x <- row(x)
		c.x <- col(x)
		sum(x * mapply(mat.ll, r = r.x, c = c.x))
	}
	c <- concordant(x)
	d <- discordant(x)
	gamma <- (c - d) / (c + d)
	gamma
}

# Approximation to polychoric matrix for initial values
cormod <- function(fulldata, K, guess, smooth = TRUE, use = 'pairwise.complete.obs')
{
	fulldata <- as.matrix(fulldata)
	nitems <- ncol(fulldata)
	cormat <- cor(fulldata, use=use)
    cormat[is.na(cormat)] <- 0
	cormat <- abs(cormat)^(1/1.15) * sign(cormat)
	if(smooth){
		eig <- eigen(cormat)
		negvalues <- eig$values < 0
		if (any(negvalues)) {
			negeig <- sum(abs(eig$value[eig$value < 0]))
			eig$value[eig$value < 0] <- 0
			L <- nitems/sum(eig$value)*eig$value[!negvalues]
			V <- eig$vector[ ,!negvalues]
			cormat <- V %*% diag(L) %*% t(V)
		}
	}
	cormat
}

# Rotate lambda coefficients
rotateLambdas <- function(so){
    F <- so$rotF
    h2 <- so$h2
    h <- matrix(rep(sqrt(1 - h2), ncol(F)), ncol = ncol(F))
    a <- F / h
    a
}

d2r <-function(d) pi*d/180

closeEnough <- function(x, low, up) all(x >= low & x <= up)

test_info <- function(pars, Theta, Alist, K){
    infolist <- list()
    for(cut in 1L:length(Alist)){
        A <- Alist[[cut]]
        info <- rep(0,nrow(Theta))
        for(j in 1L:length(K)){
            info <- info + ItemInfo(pars[[j]], A[j,], Theta)
        }
        infolist[[cut]] <- info
    }
    tmp <- 0
    for(i in 1L:length(infolist)){
        tmp <- tmp + infolist[[i]]
    }
    info <- tmp/length(infolist)
    info
}

Lambdas <- function(pars){
    lambdas <- list()
    J <- ifelse(is(pars[[length(pars)]], 'GroupPars'), length(pars)-1L, length(pars))
    for(i in 1L:J)
        lambdas[[i]] <- ExtractLambdas(pars[[i]])
    lambdas <- do.call(rbind,lambdas)
    lambdas
}

#change long pars for groups into mean in sigma
ExtractGroupPars <- function(x){
    nfact <- x@nfact
    gmeans <- x@par[1L:nfact]
    tmp <- x@par[-(1L:nfact)]
    gcov <- matrix(0, nfact, nfact)
    gcov[lower.tri(gcov, diag=TRUE)] <- tmp
    if(nfact != 1L)
        gcov <- gcov + t(gcov) - diag(diag(gcov))
    return(list(gmeans=gmeans, gcov=gcov))
}

reloadConstr <- function(par, constr, obj){
    par2 <- rep(NA, length(constr[[1L]]))
    notconstr <- rep(TRUE, length(par2))
    for(i in 1L:length(constr)){
        par2[constr[[i]]] <- par[i]
        notconstr[constr[[i]]] <- FALSE
    }
    par2[notconstr] <- par[(length(constr)+1L):length(par)]
    ind <- 1L
    for(i in 1L:length(obj)){
        obj[[i]]@par[obj[[i]]@est] <- par2[ind:(ind + sum(obj[[i]]@est) - 1L)]
        ind <- ind + sum(obj[[i]]@est)
    }
    return(obj)
}

bfactor2mod <- function(model, J){
    tmp <- tempfile('tempfile')
    unique <- sort(unique(model))
    index <- 1L:J
    tmp2 <- c()
    for(i in 1L:length(unique)){
        ind <- na.omit(index[model == unique[i]])
        comma <- rep(',', 2*length(ind))
        TF <- rep(c(TRUE,FALSE), length(ind))
        comma[TF] <- ind
        comma[length(comma)] <- ""
        tmp2 <- c(tmp2, c(paste('\nS', i, ' =', sep=''), comma))
    }
    cat(tmp2, file=tmp)
    model <- mirt.model(file=tmp, quiet = TRUE)
    unlink(tmp)
    return(model)
}

UpdateConstrain <- function(pars, constrain, invariance, nfact, nLambdas, J, ngroups, PrepList,
                            method, itemnames)
{
    #within group item constraints only
    for(g in 1L:ngroups)
        if(length(PrepList[[g]]$constrain) > 0L)
            for(i in 1L:length(PrepList[[g]]$constrain))
                constrain[[length(constrain) + 1L]] <- PrepList[[g]]$constrain[[i]]
    if('covariances' %in% invariance){ #Fix covariance accross groups (only makes sense with vars = 1)
        tmpmat <- matrix(NA, nfact, nfact)
        low_tri <- lower.tri(tmpmat)
        tmp <- c()
        tmpmats <- tmpestmats <- matrix(NA, ngroups, nfact*(nfact+1L)/2)
        for(g in 1L:ngroups){
            tmpmats[g,] <- pars[[g]][[J + 1L]]@parnum[(nfact+1L):length(pars[[g]][[J + 1L]]@parnum)]
            tmpestmats[g,] <- pars[[g]][[J + 1L]]@est[(nfact+1L):length(pars[[g]][[J + 1L]]@est)]
        }
        select <- colSums(tmpestmats) == ngroups
        for(i in 1L:length(select))
            if(select[i])
                constrain[[length(constrain) + 1L]] <- tmpmats[1L:ngroups, i]

    }
    if(any(itemnames %in% invariance)){
        matched <- na.omit(match(invariance, itemnames))
        for(i in matched){
            jj <- sum(pars[[1L]][[i]]@est)
            stopifnot(jj > 0)
            for(j in 1L:jj){
                tmp <- c()
                for(g in 1L:ngroups)
                    tmp <- c(tmp, pars[[g]][[i]]@parnum[pars[[g]][[i]]@est][j])
                constrain[[length(constrain) + 1L]] <- tmp
            }
        }
    }
    if('slopes' %in% invariance){ #Equal factor loadings
        tmpmats <- tmpests <- list()
        for(g in 1L:ngroups)
            tmpmats[[g]] <- tmpests[[g]] <- matrix(NA, J, nLambdas)
        for(g in 1L:ngroups){
            for(i in 1L:J){
                tmpmats[[g]][i,] <- pars[[g]][[i]]@parnum[1L:nLambdas]
                tmpests[[g]][i,] <- pars[[g]][[i]]@est[1L:nLambdas]
            }
        }
        for(i in 1L:J){
            for(j in 1L:nLambdas){
                tmp <- c()
                for(g in 1L:ngroups){
                    if(tmpests[[1L]][[i, j]])
                        tmp <- c(tmp, tmpmats[[g]][i,j])
                }
                constrain[[length(constrain) + 1L]] <- tmp
            }
        }
    }
    if('intercepts' %in% invariance){ #Equal item intercepts (and all other item pars)
        tmpmats <- tmpests <- list()
        for(g in 1L:ngroups)
            tmpmats[[g]] <- tmpests[[g]] <- list()
        for(g in 1L:ngroups){
            for(i in 1L:J){
                ind <- (nLambdas+1L):length(pars[[g]][[i]]@parnum)
                if(is(pars[[g]][[i]], 'dich')) ind <- ind[1L:(length(ind)-2L)]
                if(is(pars[[g]][[i]], 'partcomp')) ind <- ind[1L:(length(ind)-1L)]
                tmpmats[[g]][[i]] <- pars[[g]][[i]]@parnum[ind]
                tmpests[[g]][[i]] <- pars[[g]][[i]]@est[ind]
            }
        }
        for(i in 1L:J){
            for(j in 1L:length(tmpmats[[1L]][[i]])){
                tmp <- c()
                for(g in 1L:ngroups){
                    if(tmpests[[1L]][[i]][j])
                        tmp <- c(tmp, tmpmats[[g]][[i]][j])
                }
                constrain[[length(constrain) + 1L]] <- tmp
            }
        }
    }
    #remove redundent constraints    
    if(TRUE){
        redun <- rep(FALSE, length(constrain))
        if(length(constrain) > 0L){
            for(i in 1L:length(redun)){
                for(j in 1L:length(redun)){
                    if(j < i){
                        if(all(constrain[[i]] %in% constrain[[j]] ||
                                all(constrain[[j]] %in% constrain[[i]]))){
                            if(length(constrain[[i]]) < length(constrain[[j]])) redun[i] <- TRUE
                            else redun[j] <- TRUE
                        }
                    }
                }
            }
        }
        constrain[redun] <- NULL
    }
    return(constrain)
}

ReturnPars <- function(PrepList, itemnames, random, MG = FALSE){
    parnum <- par <- est <- item <- parname <- gnames <- class <-
        lbound <- ubound <- prior.type <- prior_1 <- prior_2 <- c()
    if(!MG) PrepList <- list(full=PrepList)
    for(g in 1L:length(PrepList)){
        tmpgroup <- PrepList[[g]]$pars
        for(i in 1L:length(tmpgroup)){
            if(i <= length(itemnames))
                item <- c(item, rep(itemnames[i], length(tmpgroup[[i]]@parnum)))
            class <- c(class, rep(class(tmpgroup[[i]]), length(tmpgroup[[i]]@parnum)))
            parname <- c(parname, names(tmpgroup[[i]]@par))
            parnum <- c(parnum, tmpgroup[[i]]@parnum)
            par <- c(par, tmpgroup[[i]]@par)
            est <- c(est, tmpgroup[[i]]@est)
            lbound <- c(lbound, tmpgroup[[i]]@lbound)
            ubound <- c(ubound, tmpgroup[[i]]@ubound)
            prior.type <- c(prior.type, tmpgroup[[i]]@prior.type)
            prior_1 <- c(prior_1, tmpgroup[[i]]@prior_1)
            prior_2 <- c(prior_2, tmpgroup[[i]]@prior_2)
        }
        item <- c(item, rep('GROUP', length(tmpgroup[[i]]@parnum)))
    }
    if(length(random) > 0L){
        for(i in 1L:length(random)){            
            parname <- c(parname, names(random[[i]]@par))
            parnum <- c(parnum, random[[i]]@parnum)
            par <- c(par, random[[i]]@par)
            est <- c(est, random[[i]]@est)
            lbound <- c(lbound, random[[i]]@lbound)
            ubound <- c(ubound, random[[i]]@ubound)            
            prior.type <- c(prior.type, random[[i]]@prior.type)
            prior_1 <- c(prior_1, random[[i]]@prior_1)
            prior_2 <- c(prior_2, random[[i]]@prior_2)
            class <- c(class, rep('RandomPars', length(random[[i]]@parnum)))
            item <- c(item, rep('RANDOM', length(random[[i]]@parnum))) 
        }
    }
    gnames <- rep(names(PrepList), each = length(est)/length(PrepList))
    ret <- data.frame(group=gnames, item=item, class=class, name=parname, parnum=parnum, value=par,
                      lbound=lbound, ubound=ubound, est=est, prior.type=prior.type,
                      prior_1=prior_1, prior_2=prior_2)
    ret
}

UpdatePrepList <- function(PrepList, pars, random, MG = FALSE){
    currentDesign <- ReturnPars(PrepList, PrepList[[1L]]$itemnames, random=random, MG = TRUE)
    if(!all(as.matrix(currentDesign[,c('group', 'item', 'class', 'name', 'parnum')]) == 
                as.matrix(pars[,c('group', 'item', 'class', 'name', 'parnum')])))
        stop('Critical internal parameter labels do not match those returned from pars = \'values\'')
    if(!all(sapply(currentDesign, class) == sapply(pars, class)))
        stop('pars input does not contain the appropriate classes, which should match pars = \'values\'')
    if(!all(unique(pars$prior.type) %in% c('none', 'norm', 'beta', 'lnorm'))) 
        stop('prior.type input in pars contains invalid prior types')
    if(!MG) PrepList <- list(PrepList)    
    len <- length(PrepList[[length(PrepList)]]$pars)
    maxparnum <- max(PrepList[[length(PrepList)]]$pars[[len]]@parnum)
    ind <- 1L
    for(g in 1L:length(PrepList)){
        for(i in 1L:length(PrepList[[g]]$pars)){
            for(j in 1L:length(PrepList[[g]]$pars[[i]]@par)){
                PrepList[[g]]$pars[[i]]@par[j] <- pars[ind,'value']
                PrepList[[g]]$pars[[i]]@est[j] <- as.logical(pars[ind,'est'])
                PrepList[[g]]$pars[[i]]@lbound[j] <- pars[ind,'lbound']
                PrepList[[g]]$pars[[i]]@ubound[j] <- pars[ind,'ubound']
                PrepList[[g]]$pars[[i]]@prior.type[j] <- as.character(pars[ind,'prior.type'])
                PrepList[[g]]$pars[[i]]@prior_1[j] <- pars[ind,'prior_1']
                PrepList[[g]]$pars[[i]]@prior_2[j] <- pars[ind,'prior_2']
                ind <- ind + 1L
            }
            PrepList[[g]]$pars[[i]]@any.prior <- any(c('norm','lnorm','beta') %in% 
                                                         PrepList[[g]]$pars[[i]]@prior.type)
        }
    }
    if(length(random) > 0L){
        for(i in 1L:length(random)){
            for(j in 1L:length(random[[i]]@par)){
                random[[i]]@par[j] <- pars[ind,'value']
                random[[i]]@est[j] <- as.logical(pars[ind,'est'])
                random[[i]]@lbound[j] <- pars[ind,'lbound']
                random[[i]]@ubound[j] <- pars[ind,'ubound']
                ind <- ind + 1L
            }
        }
        attr(PrepList, 'random') <- random
    }
    if(!MG) PrepList <- PrepList[[1L]]
    return(PrepList)
}

#new gradient and hessian with priors
DerivativePriors <- function(x, grad, hess){
    if(any(x@prior.type %in% 'norm')){
        ind <- x@prior.type %in% 'norm'
        val <- x@par[ind]
        mu <- x@prior_1[ind]
        s <- x@prior_2[ind]
        g <- -(val - mu)/(s^2)
        h <- -1/(s^2)
        grad[ind] <- grad[ind] + g
        if(length(val) == 1L) hess[ind, ind] <- hess[ind, ind] + h
        else diag(hess[ind, ind]) <- diag(hess[ind, ind]) + h
    }
    if(any(x@prior.type %in% 'lnorm')){
        ind <- x@prior.type %in% 'lnorm'
        val <- x@par[ind]
        val <- ifelse(val > 0, val, 1e-10)
        lval <- log(val)
        mu <- x@prior_1[ind]
        s <- x@prior_2[ind]
        g <- -(lval - mu)/(val * s^2) - 1/val 
        h <- 1/(val^2) - 1/(val^2 * s^2) - (lval - mu)/(val^2 * s^2)
        grad[ind] <- grad[ind] + g
        if(length(val) == 1L) hess[ind, ind] <- hess[ind, ind] + h
        else diag(hess[ind, ind]) <- diag(hess[ind, ind]) + h
    }
    if(any(x@prior.type %in% 'beta')){
        ind <- x@prior.type %in% 'beta'
        val <- x@par[ind]
        val <- ifelse(val < 1e-10, 1e-10, val)
        val <- ifelse(val > 1-1e-10, 1-1e-10, val)
        a <- x@prior_1[ind]
        b <- x@prior_2[ind]        
        g <- (a - 1)/val - (b-1)/(1-val)
        h <- -(a - 1)/(val^2) - (b-1) / (1-val)^2        
        grad[ind] <- grad[ind] + g    
        if(length(val) == 1L) hess[ind, ind] <- hess[ind, ind] + h
        else diag(hess[ind, ind]) <- diag(hess[ind, ind]) + h
    }
    return(list(grad=grad, hess=hess))
}

#new likelihood with priors
LL.Priors <- function(x, LL){
    if(any(x@prior.type %in% 'norm')){
        ind <- x@prior.type %in% 'norm'
        val <- x@par[ind]
        u <- x@prior_1[ind]
        s <- x@prior_2[ind]
        for(i in 1L:length(val)){
            tmp <- dnorm(val[i], u[i], s[i], log=TRUE)            
            LL <- LL + ifelse(tmp == -Inf, log(1e-100), tmp)
        }
    }
    if(any(x@prior.type %in% 'lnorm')){
        ind <- x@prior.type %in% 'lnorm'
        val <- x@par[ind]
        val <- ifelse(val > 0, val, 1e-100)
        u <- x@prior_1[ind]
        s <- x@prior_2[ind]
        for(i in 1L:length(val)){
            tmp <- dlnorm(val[i], u[i], s[i], log=TRUE)
            LL <- LL + ifelse(tmp == -Inf, log(1e-100), tmp)
        }
    }
    if(any(x@prior.type %in% 'beta')){
        ind <- x@prior.type %in% 'beta'
        val <- x@par[ind]
        a <- x@prior_1[ind]
        b <- x@prior_2[ind]
        for(i in 1L:length(val)){
            tmp <- dbeta(val[i], a[i], b[i], log=TRUE)
            LL <- LL + ifelse(tmp == -Inf, log(1e-100), tmp)
        }
    }
    return(LL)
}

ItemInfo <- function(x, Theta, cosangle, total.info = TRUE){
    P <- ProbTrace(x, Theta)
    dx <- DerivTheta(x, Theta)
    info <- matrix(0, nrow(Theta), ncol(P))
    cosanglefull <- matrix(cosangle, nrow(P), length(cosangle), byrow = TRUE)
    if(ncol(cosanglefull) < ncol(dx$grad[[1L]]))
        cosanglefull <- cbind(cosanglefull, matrix(1, nrow(cosanglefull),
                                                   ncol(dx$grad[[1L]]) - ncol(cosanglefull)))
    for(i in 1L:x@ncat){
        dx$grad[[i]] <- matrix(rowSums(dx$grad[[i]] * cosanglefull))
        dx$hess[[i]] <- matrix(rowSums(dx$hess[[i]] * cosanglefull))
    }
    for(i in 1L:x@ncat)
        info[,i] <- (dx$grad[[i]])^2 / P[ ,i] - dx$hess[[i]]
    if(total.info) info <- matrix(rowSums(info))
    return(info)
}

nameInfoMatrix <- function(info, correction, L, npars){
    #give info meaningful names for wald test
    parnames <- names(correction)
    tmp <- outer(1L:npars, rep(1L, npars))
    matind <- matrix(0, ncol(tmp), nrow(tmp))
    matind[lower.tri(matind, diag = TRUE)] <- tmp[lower.tri(tmp, diag = TRUE)]
    matind <- matind * L
    matind[matind == 0 ] <- NA
    shortnames <- c()
    for(i in 1L:length(correction)){
        keep <- is.na(matind[ , 1L])
        while(all(keep)){
            matind <- matind[-1L, -1L, drop = FALSE]
            keep <- is.na(matind[ , 1L])
        }
        tmp <- paste0(parnames[i], paste0('.', matind[!keep, 1L], collapse=''))
        shortnames <- c(shortnames, tmp)
        matind <- matind[keep, keep, drop = FALSE]
    }
    colnames(info) <- rownames(info) <- shortnames
    return(info)
}

maketabData <- function(stringfulldata, stringtabdata, group, groupNames, nitem, K, itemloc,
                        Names, itemnames){
    tabdata2 <- lapply(strsplit(stringtabdata, split='/'), as.integer)
    tabdata2 <- do.call(rbind, tabdata2)
    tabdata2[tabdata2 == 99999] <- NA
    tabdata <- matrix(0, nrow(tabdata2), sum(K))
    for(i in 1L:nitem){
        uniq <- sort(na.omit(unique(tabdata2[,i])))
        if(length(uniq) < K[i]) uniq <- 0L:(K[i]-1L)        
        for(j in 1L:length(uniq))
            tabdata[,itemloc[i] + j - 1L] <- as.integer(tabdata2[,i] == uniq[j])
    }
    tabdata[is.na(tabdata)] <- 0
    colnames(tabdata) <- Names
    colnames(tabdata2) <- itemnames
    ret1 <- ret2 <- vector('list', length(groupNames))
    for(g in 1L:length(groupNames)){
        Freq <- numeric(length(stringtabdata))
        tmpstringdata <- stringfulldata[group == groupNames[g]]
        Freq[stringtabdata %in% tmpstringdata] <- table(match(tmpstringdata, stringtabdata))
        ret1[[g]] <- cbind(tabdata, Freq)
        ret2[[g]] <- cbind(tabdata2, Freq)
    }
    ret <- list(tabdata=ret1, tabdata2=ret2)
    ret
}

makeopts <- function(method = 'MHRM', draws = 2000, calcLL = TRUE, quadpts = NaN,
                     rotate = 'varimax', Target = NaN, SE = TRUE, verbose = TRUE,
                     SEtol = .0001, grsm.block = NULL, D = 1,
                     rsm.block = NULL, calcNull = TRUE, BFACTOR = FALSE,
                     technical = list(), use = 'pairwise.complete.obs',
                     SE.type = 'MHRM', large = NULL, accelerate = TRUE, ...)
{
    opts <- list()
    D <- 1
    opts$method = method
    opts$draws = draws
    opts$calcLL = calcLL
    opts$quadpts = quadpts
    opts$rotate = rotate
    opts$Target = Target
    opts$SE = SE
    opts$SE.type = SE.type
    opts$verbose = verbose
    opts$SEtol = SEtol
    opts$grsm.block = grsm.block
    opts$D = D
    opts$rsm.block = rsm.block
    opts$calcNull = calcNull  
    opts$BFACTOR = BFACTOR
    opts$accelerate = accelerate
    if(SE.type == 'SEM' && SE) opts$accelerate <- FALSE
    if(BFACTOR && is.nan(quadpts)) opts$quadpts <- 21
    opts$technical <- technical
    opts$use <- use
    opts$MAXQUAD <- ifelse(is.null(technical$MAXQUAD), 10000, technical$MAXQUAD)
    opts$NCYCLES <- ifelse(is.null(technical$NCYCLES), 2000, technical$NCYCLES)
    if(opts$method == 'EM')
        opts$NCYCLES <- ifelse(is.null(technical$NCYCLES), 500, technical$NCYCLES)
    opts$BURNIN <- ifelse(is.null(technical$BURNIN), 150, technical$BURNIN)
    opts$SEMCYCLES <- ifelse(is.null(technical$SEMCYCLES), 50, technical$SEMCYCLES)
    opts$KDRAWS  <- ifelse(is.null(technical$KDRAWS), 1L, technical$KDRAWS)
    opts$TOL <- ifelse(is.null(technical$TOL), if(method == 'EM') 1e-4 else 1e-3, technical$TOL)        
    opts$MSTEPTOL <- ifelse(is.null(technical$MSTEPTOL), opts$TOL/1000, technical$MSTEPTOL)
    if(opts$method == 'MHRM' || opts$method =='MIXED' || SE.type == 'MHRM')
        set.seed(12345)
    if(!is.null(technical$set.seed)) set.seed(technical$set.seed)
    opts$gain <- c(0.05,0.5,0.004)
    if(!is.null(technical$gain)){
        if(length(technical$gain) == 3 && is.numeric(technical$gain))
            opts$gain <- technical$gain
    }
    opts$NULL.MODEL <- ifelse(is.null(technical$NULL.MODEL), FALSE, TRUE)
    opts$USEEM <- ifelse(method == 'EM', TRUE, FALSE)
    opts$returnPrepList <- FALSE
    opts$PrepList <- NULL
    if(!is.null(large)){
        if(is.logical(large))
            if(large) opts$returnPrepList <- TRUE
        if(is.list(large)) opts$PrepList <- large
    }    
    if(!is.null(technical$customK)) opts$calcNull <- FALSE
    return(opts)
}

reloadPars <- function(longpars, pars, ngroups, J){
    return(.Call('reloadPars', longpars, pars, ngroups, J))
}

computeItemtrace <- function(pars, Theta, itemloc, offterm = matrix(0L, 1L, length(itemloc)-1L), 
                             NO.CUSTOM=FALSE){
    if(!NO.CUSTOM){
        if(any(sapply(pars, class) %in% 'custom')){ #sanity check, not important for custom anyway
            itemtrace <- .Call('computeItemTrace', pars, Theta, itemloc, offterm)
            for(i in 1L:(length(pars)-1L))
                if(class(pars[[i]]) == 'custom')
                    itemtrace[,itemloc[i]:(itemloc[i+1L] - 1L)] <- ProbTrace(pars[[i]], Theta=Theta)
            return(itemtrace)
        } else {
            return(.Call('computeItemTrace', pars, Theta, itemloc, offterm))
        }
    } else {
        return(.Call('computeItemTrace', pars, Theta, itemloc, offterm))
    }
}

assignItemtrace <- function(pars, itemtrace, itemloc){
    for(i in 1L:(length(pars)-1L))
        pars[[i]]@itemtrace <- itemtrace[ ,itemloc[i]:(itemloc[i+1L] - 1L)]
    pars[[length(pars)]]@itemtrace <- itemtrace
    pars
}

BL.SE <- function(pars, Theta, theta, prior, BFACTOR, itemloc, PrepList, ESTIMATE, constrain,
                  specific=NULL, sitems=NULL){
    LL <- function(p, est, longpars, pars, ngroups, J, Theta, PrepList, specific, sitems,
                   NO.CUSTOM){
        longpars[est] <- p
        pars2 <- reloadPars(longpars=longpars, pars=pars, ngroups=ngroups, J=J)
        gstructgrouppars <- prior <- Prior <- vector('list', ngroups)
        for(g in 1L:ngroups){
            gstructgrouppars[[g]] <- ExtractGroupPars(pars2[[g]][[J+1L]])
            if(BFACTOR){
                prior[[g]] <- dnorm(theta, 0, 1)
                prior[[g]] <- prior[[g]]/sum(prior[[g]])                
                Prior[[g]] <- apply(expand.grid(prior[[g]], prior[[g]]), 1, prod)
                next
            }
            Prior[[g]] <- mvtnorm::dmvnorm(Theta,gstructgrouppars[[g]]$gmeans,
                                           gstructgrouppars[[g]]$gcov)
            Prior[[g]] <- Prior[[g]]/sum(Prior[[g]])
        }
        LL <- 0
        for(g in 1L:ngroups){
            if(BFACTOR){
                expected <- Estep.bfactor(pars=pars2[[g]], tabdata=PrepList[[g]]$tabdata,
                                            Theta=Theta, prior=prior[[g]],
                                            specific=specific, sitems=sitems,
                                            itemloc=itemloc, NO.CUSTOM=NO.CUSTOM)$expected
            } else {
                expected <- Estep.mirt(pars=pars2[[g]], tabdata=PrepList[[g]]$tabdata,
                                       Theta=Theta, prior=Prior[[g]], itemloc=itemloc, 
                                       NO.CUSTOM=NO.CUSTOM)$expected
            }
            LL <- LL + sum(PrepList[[g]]$tabdata[,ncol(PrepList[[g]]$tabdata)] * log(expected))
        }
        LL
    }
    
    L <- ESTIMATE$L
    longpars <- ESTIMATE$longpars
    rlist <- ESTIMATE$rlist
    infological=ESTIMATE$infological
    ngroups <- length(pars)
    J <- length(pars[[1L]]) - 1L
    est <- c()
    for(g in 1L:ngroups)
        for(j in 1L:(J+1L))
            est <- c(est, pars[[g]][[j]]@est)
    shortpars <- longpars[est]
    gstructgrouppars <- vector('list', ngroups)
    for(g in 1L:ngroups)
            gstructgrouppars[[g]] <- ExtractGroupPars(pars[[g]][[J+1L]])
    for(g in 1L:ngroups){
        for(i in 1L:J){
            tmp <- c(itemloc[i]:(itemloc[i+1L] - 1L))
            pars[[g]][[i]]@rs <- rlist[[g]]$r1[, tmp]
        }
    }
    NO.CUSTOM <- !any(sapply(pars, class) %in% 'custom')
    hess <- numDeriv::hessian(LL, x=shortpars, est=est, longpars=longpars,
                              pars=pars, ngroups=ngroups, J=J,
                              Theta=Theta, PrepList=PrepList,
                              specific=specific, sitems=sitems, NO.CUSTOM=NO.CUSTOM)
    Hess <- matrix(0, length(longpars), length(longpars))
    Hess[est, est] <- -hess
    Hess <- L %*% Hess %*% L
    info <- Hess[infological, infological]
    ESTIMATE <- loadESTIMATEinfo(info=info, ESTIMATE=ESTIMATE, constrain=constrain)
    return(ESTIMATE)
}

loadESTIMATEinfo <- function(info, ESTIMATE, constrain){
    longpars <- ESTIMATE$longpars
    pars <- ESTIMATE$pars
    ngroups <- length(pars)
    J <- length(pars[[1L]]) - 1L
    info <- nameInfoMatrix(info=info, correction=ESTIMATE$correction, L=ESTIMATE$L,
                           npars=length(longpars))
    ESTIMATE$info <- info
    SEtmp <- diag(solve(info))
    if(any(SEtmp < 0)){
        warning("Negative SEs set to NaN.\n")
        SEtmp[SEtmp < 0 ] <- NaN
    }
    SEtmp <- sqrt(SEtmp)
    SE <- rep(NA, length(longpars))
    SE[ESTIMATE$estindex_unique] <- SEtmp
    index <- 1L:length(longpars)
    if(length(constrain) > 0)
        for(i in 1L:length(constrain))
            SE[index %in% constrain[[i]][-1L]] <- SE[constrain[[i]][1L]]
    ind1 <- 1L
    for(g in 1L:ngroups){
        for(i in 1L:(J+1L)){
            ind2 <- ind1 + length(pars[[g]][[i]]@par) - 1L
            pars[[g]][[i]]@SEpar <- SE[ind1:ind2]
            ind1 <- ind2 + 1L
        }
    }
    ESTIMATE$pars <- pars
    return(ESTIMATE)
}

SEM.SE <- function(est, pars, constrain, PrepList, list, Theta, theta, BFACTOR, ESTIMATE, DERIV){
    TOL <- sqrt(list$TOL)
    itemloc <- list$itemloc
    J <- length(itemloc) - 1L
    L <- ESTIMATE$L
    MSTEPTOL <- list$MSTEPTOL
    ngroups <- ESTIMATE$ngroups
    NCYCLES <- ESTIMATE$cycles
    if(NCYCLES <= 5L) stop('SEM can not be computed due to short EM history')
    BFACTOR <- list$BFACTOR
    gitemtrace <- gstructgrouppars <- prior <- Prior <- rlist <- vector('list', ngroups)
    estpars <- ESTIMATE$estpars
    redun_constr <- ESTIMATE$redun_constr
    EMhistory <- ESTIMATE$EMhistory
    MLestimates <- EMhistory[nrow(EMhistory), ]
    UBOUND <- ESTIMATE$UBOUND
    LBOUND <- ESTIMATE$LBOUND
    estindex <- estpars
    estindex[estpars] <- est
    rij <- 1
    prodlist <- PrepList[[1L]]$prodlist
    nfact <- ncol(Theta)
    gTheta <- vector('list', ngroups)
    ANY.PRIOR <- rep(FALSE, ngroups)
    NO.CUSTOM <- !any(sapply(pars, class) %in% 'custom')
    for(g in 1L:ngroups){
        gTheta[[g]] <- Theta 
        if(length(prodlist) > 0L)
            gTheta[[g]] <- prodterms(gTheta[[g]],prodlist)
        ANY.PRIOR[g] <- any(sapply(pars[[g]], function(x) x@any.prior))
    }
    
    for (cycles in 3L:NCYCLES){

        longpars <- MLestimates
        longpars[estindex] <- EMhistory[cycles, estindex]
        if(length(constrain) > 0L)
            for(i in 1L:length(constrain))
                longpars[constrain[[i]][-1L]] <- longpars[[constrain[[i]][1L]]]
        pars <- reloadPars(longpars=longpars, pars=pars, ngroups=ngroups, J=J)

        for(g in 1L:ngroups){
            gstructgrouppars[[g]] <- ExtractGroupPars(pars[[g]][[J+1L]])
            if(BFACTOR){
                prior[[g]] <- dnorm(theta, 0, 1)
                prior[[g]] <- prior[[g]]/sum(prior[[g]])                
                Prior[[g]] <- apply(expand.grid(prior[[g]], prior[[g]]), 1, prod)
                next
            }
            Prior[[g]] <- mvtnorm::dmvnorm(gTheta[[g]][ ,1L:nfact,drop=FALSE],gstructgrouppars[[g]]$gmeans,
                                           gstructgrouppars[[g]]$gcov)
            Prior[[g]] <- Prior[[g]]/sum(Prior[[g]])
        }
        #Estep
        for(g in 1L:ngroups){
            if(BFACTOR){
                rlist[[g]] <- Estep.bfactor(pars=pars[[g]], tabdata=PrepList[[g]]$tabdata,
                                            Theta=gTheta[[g]], prior=prior[[g]], Prior=Prior[[g]],
                                            specific=list$specific, sitems=list$sitems,
                                            itemloc=itemloc, NO.CUSTOM=NO.CUSTOM)
            } else {
                rlist[[g]] <- Estep.mirt(pars=pars[[g]], tabdata=PrepList[[g]]$tabdata,
                                         Theta=gTheta[[g]], prior=Prior[[g]], itemloc=itemloc,
                                         NO.CUSTOM=NO.CUSTOM)
            }
        }
        for(g in 1L:ngroups){
            for(i in 1L:J){
                tmp <- c(itemloc[i]:(itemloc[i+1L] - 1L))
                pars[[g]][[i]]@rs <- rlist[[g]]$r1[, tmp]
            }
        }
        longpars <- Mstep(pars=pars, est=estpars, longpars=longpars, ngroups=ngroups, J=J, rlist=rlist,
                          gTheta=gTheta, itemloc=itemloc, Prior=Prior, ANY.PRIOR=ANY.PRIOR, 
                          NO.CUSTOM=NO.CUSTOM, PrepList=PrepList, L=L, UBOUND=UBOUND, LBOUND=LBOUND,
                          constrain=constrain, cycle=cycles, DERIV=DERIV)
        rijlast <- rij
        denom <- (EMhistory[cycles, estindex] - MLestimates[estindex])
        sign <- sign(denom)
        if(sign == 0) sign <- 1
        if(abs(denom) < 1e-10) denom <- 1e-10 * sign
        rij <- (longpars[estpars & !redun_constr] - MLestimates[estpars & !redun_constr]) / denom
        if(all(abs(rij - rijlast) < TOL)) break
    } #END EM
    return(rij)
}

make.randomdesign <- function(random, longdata, covnames, itemdesign, N){    
    itemcovnames <- colnames(itemdesign)
    J <- nrow(itemdesign)    
    ret <- vector('list', length(random))
    for(i in 1L:length(random)){
        f <- gsub(" ", "", as.character(random[[i]])[2L])
        splt <- strsplit(f, '\\|')[[1L]]
        gframe <- model.frame(as.formula(paste0('~',splt[2L])), longdata)        
        sframe <- model.frame(as.formula(paste0('~',splt[1L])), longdata)
        if(colnames(gframe) %in% covnames){
            between <- TRUE
        } else if(colnames(gframe) %in% itemcovnames){
            between <- FALSE
        } else stop('grouping variable not in itemdesign or covdata')
        if(between){            
            gframe <- gframe[1:N, , drop=FALSE]            
            sframe <- sframe[1:N, , drop=FALSE]
        } else {
            gframe <- itemdesign[, which(colnames(gframe) == itemcovnames), drop=FALSE]
            sframe <- itemdesign[, which(colnames(sframe) == itemcovnames), drop=FALSE]
        }        
        matpar <- diag(ncol(gframe) + ncol(sframe))
        estmat <- lower.tri(matpar, diag=TRUE)
        ndim <- ncol(matpar)
        if(strsplit(f, '+')[[1L]][[1L]] == '-') 
            estmat[lower.tri(estmat)] <- FALSE        
        fn <- paste0('COV_', c(colnames(gframe), colnames(sframe)))
        FNCOV <- outer(fn, c(colnames(gframe), colnames(sframe)), FUN=paste, sep='_')
        par <- matpar[lower.tri(matpar, diag=TRUE)]
        est <- estmat[lower.tri(estmat, diag=TRUE)]
        names(par) <- names(est) <- FNCOV[lower.tri(FNCOV, diag=TRUE)]     
        drawvals <- matrix(0, length(unique(gframe)[[1L]]), ndim, 
                           dimnames=list(unique(gframe)[[1L]], NULL))        
        mtch <- match(gframe[[1L]], rownames(drawvals))
        gdesign <- matrix(1, nrow(gframe), 1L, dimnames = list(NULL, colnames(gframe))) 
        if(ncol(sframe) != 0L) 
            gdesign <- cbind(model.matrix(as.formula(paste0('~',splt[1L])), sframe), gdesign)
        tmp <- matrix(-Inf, ndim, ndim)
        diag(tmp) <- 1e-4
        lbound <- tmp[lower.tri(tmp, diag=TRUE)]
        ret[[i]] <- new('RandomPars', 
                        par=par,
                        est=est,
                        ndim=ndim,
                        lbound=lbound,
                        ubound=rep(Inf, length(par)),
                        gframe=gframe,
                        gdesign=gdesign,                        
                        between=between,
                        cand.t.var=.5,
                        any.prior=FALSE,
                        prior.type=rep('none', length(par)),
                        prior_1=rep(NaN,length(par)),
                        prior_2=rep(NaN,length(par)),
                        drawvals=drawvals,
                        mtch=mtch)        
    }    
    ret
}

OffTerm <- function(random, J, N){
    ret <- matrix(0, N, J)
    for(i in 1L:length(random)){
        if(random[[i]]@between){
            tmp <- rowSums(random[[i]]@gdesign*random[[i]]@drawvals[random[[i]]@mtch, ,drop=FALSE])
            for(j in 1L:J) ret[,j] <- ret[,j] + tmp
        } else {
            tmp <- matrix(rowSums(random[[i]]@gdesign *
                          random[[i]]@drawvals[random[[i]]@mtch, ,drop=FALSE]), nrow(ret), J,
                          byrow=TRUE)
            ret <- ret + tmp
        }
    }
    ret
}

reloadRandom <- function(random, longpars, parstart){    
    ind1 <- parstart
    for(i in 1L:length(random)){
        ind2 <- ind1 + length(random[[i]]@par) - 1L
        random[[i]]@par <- longpars[ind1:ind2]
        ind1 <- ind2 + 1L
    }
    random
}

smooth.cov <- function(x){
    eigens <- eigen(x)
    if(min(eigens$values) < .Machine$double.eps){
        eigens$values[eigens$values < .Machine$double.eps] <- 100 * 
            .Machine$double.eps
        nvar <- dim(x)[1]
        tot <- sum(eigens$values)
        eigens$values <- eigens$values * nvar/tot
        x <- eigens$vectors %*% diag(eigens$values) %*% t(eigens$vectors)
    }
    x
}
