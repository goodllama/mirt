#' Imputing plausible data for missing values
#' 
#' Given an estimated model from any of mirt's model fitting functions and an estimate of the latent trait, 
#' impute plausible missing data values. Returns the original data in a \code{data.frame} 
#' without any NA values.
#' 
#'
#' @aliases imputeMissing
#' @param x an estimated model x from the mirt package
#' @param Theta a matrix containing the estimates of the latent trait scores (via \code{\link{fscores}})
#' @author Phil Chalmers \email{rphilip.chalmers@@gmail.com}
#' @keywords inpute data
#' @export imputeMissing
#' @examples 
#' \dontrun{
#' dat <- expand.table(LSAT7)
#' (original <- mirt(dat, 1))
#' NAperson <- sample(1:nrow(dat), 20, replace = TRUE)
#' NAitem <- sample(1:ncol(dat), 20, replace = TRUE)
#' for(i in 1:20)
#'     dat[NAperson[i], NAitem[i]] <- NA
#' (mod <- mirt(dat, 1))
#' scores <- fscores(mod, method = 'MAP', full.scores = TRUE)
#'
#' #re-estimate imputed dataset (good to do this several times and average over)
#' fulldata <- imputeMissing(mod, scores[,'F1', drop = FALSE])
#' (fullmod <- mirt(fulldata, 1))
#' 
#' 
#' }
imputeMissing <- function(x, Theta){    
    set.seed(proc.time()[3])
    if(is(x, 'MixedClass'))
        stop('mixedmirt xs not yet supported')       
    pars <- x@pars        
    K <- x@K        
    J <- length(K)                
    data <- x@data
    N <- nrow(data)
    Nind <- 1:N
    for (i in 1:J){
        if(!any(is.na(data[,i]))) next
        P <- ProbTrace(x=pars[[i]], Theta=Theta)        
        NAind <- Nind[is.na(data[,i])]
        for(j in 1:length(NAind)){            
            sampl <- sample(1:ncol(P), 1, prob = P[NAind[j], , drop = FALSE])
            if(any(class(pars[[i]]) %in% c('dich', 'gpcm', 'partcomp'))) 
                sampl <- sampl - 1 
            data[NAind[j], i] <- sampl            
        }        
    }
    return(data)
}