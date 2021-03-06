#' Extract an item object from mirt objects
#'
#' Extract the internal mirt objects from any estimated model.
#'
#' @aliases extract.item
#' @param x mirt model of class 'ExploratoryClass', 'ConfirmatoryClass', or 'MultipleGroupClass'
#' @param item a number or character signifying which item to extract
#' @param group a number signifying which group the item should be extracted from (applies to
#' 'MultipleGroupClass' only)
#' @param drop.zeros logical; drop slope values that are numerically close to zero to reduce dimensionality?
#' Useful in objects returned from \code{\link{bfactor}} or other confirmatory models that contain several 
#' zero slopes
#' @keywords extract
#' @export extract.item
#' @examples
#'
#' \dontrun{
#' mod <- mirt(Science, 1)
#' extr.1 <- extract.item(mod, 1)
#' }
extract.item <- function(x, item, group = NULL, drop.zeros = FALSE){
    inames <- colnames(x@data)
    ind <- 1L:length(inames)
    if(!is.numeric(item)) item <- ind[inames == item]
    if(is(x, 'MultipleGroupClass')){
        if(is.null(group)) stop('Which group are you trying to extract from?')
        ret <- x@cmods[[group]]@pars[[item]]
    } else {
        ret <- x@pars[[item]]
    }
    if(drop.zeros){
        zeros <- ret@par > -1e-8 & ret@par < 1e-8
        zeros[-c(1L:ret@nfact)] <- FALSE
        ret@par <- ret@par[!zeros]
        ret@est <- ret@est[!zeros]
        ret@parnum <- ret@parnum[!zeros]
        ret@nfact <- sum(!zeros[c(1L:ret@nfact)])        
    }
    ret
}
