# methods.R - DESC
# FLBRP/R/methods.R

# Copyright FLR Team, 2017
# Authors: Laurie Kell <laurie@seaplusplus.co.uk>
#          Iago Mosqueira (EC JRC) <iago.mosqueira@ec.europa.eu>
#          Finlay Scott (EC JRC) <finlay.scott@ec.europa.eu>
#
# Distributed under the terms of the GNU Public License v 3.0

# brp {{{

#' @title Fit an FLBRP object
#' 
#' @description 
#' This method carries out the necessary calculation to obtain the reference
#' points for an object of class `FLBRP`. Results of the calculation are stored
#' in `@refpts` slot of the object, and the object is then returned.
#' 
#' @param object An object of class `FLBRP`
#' 
#' @return An object of class \code{FLBRP} with reference points estimated
#' 
#' @docType methods
#' @rdname brp
#' 
#' @seealso [FLBRP] 
#' 
#' @examples
#' data(ple4brp)
#'
#' ple4brp <- brp(ple4brp)
#' refpts(ple4brp)

setMethod('brp', signature(object='FLBRP'),
  function(object)
  {
    # check model is supported by brp
    if(!SRNameCode(SRModelName(model(object))) %in% seq(1,6))
      stop(paste("FLSR model (", SRNameCode(SRModelName(model(object))),
        ") in FLBRP object can not be used by brp. See ?ab"))

    # check needed slots are filled up
    for(i in c('landings.sel', 'discards.sel', 'bycatch.harvest', 'stock.wt',
      'landings.wt','discards.wt', 'bycatch.wt','m','mat','harvest.spwn', 'm.spwn',
      'availability'))
      if(all(is.na(slot(object, i))))
        stop("missing necessary information in slot ", i)

    # check dims in object and params
    iter <- c(dims(object)$iter, length(dimnames(params(object))$iter))
    # if > 1, they should be equal
    if(all(iter > 1))
      if(iter[1] != iter[2])
        stop('iter in FLQuant slots and params do not match, ',
          paste(iter, collapse=' vs. '))

    # extend refpts as needed
    iter <- max(iter)
    if(iter > 1 && dims(refpts(object))$iter == 1)
      refpts <- propagate(refpts(object), iter, fill.iter=TRUE)
    else if(iter > 1 && dims(refpts(object))$iter != iter)
      stop("iters in refpts and object slots do not match")
    else
      refpts <- refpts(object)

    if ("virgin" %in% dimnames(refpts)$refpt){
      refpts@.Data["virgin",,         ] <- as.numeric(NA)
      refpts@.Data["virgin", "harvest",] <- 0}

    res <- .Call("brp", object, refpts, SRNameCode(SRModelName(object@model)),
      FLQuant(c(params(object)),dimnames=dimnames(params(object))),
      PACKAGE = "FLBRP")

    return(res)
  }) # }}}

# landings.n {{{
setMethod('landings.n', signature(object='FLBRP'),
  function(object) {
    # check model is supported by brp
    if(!SRNameCode(SRModelName(model(object))) %in% seq(1,6))
      stop(paste("FLSR model (", SRNameCode(SRModelName(model(object))),
        ")in FLBRP object can not be used by brp. See ?ab"))

    .Call('landings_n', object, SRNameCode(SRModelName(object@model)),
              FLQuant(c(params(object)),dimnames=dimnames(params(object))))
  }
) # }}}

# discards.n {{{
setMethod('discards.n', signature(object='FLBRP'),
  function(object) {
    # check model is supported by brp
    if(!SRNameCode(SRModelName(model(object))) %in% seq(1,6))
      stop(paste("FLSR model (", SRNameCode(SRModelName(model(object))),
        ")in FLBRP object can not be used by brp. See ?ab"))

   .Call('discards_n', object, SRNameCode(SRModelName(object@model)),
              FLQuant(c(params(object)),dimnames=dimnames(params(object))))
  }
) # }}}

# stock.n {{{
setMethod('stock.n', signature(object='FLBRP'),
  function(object)
  {
    # check model is supported by brp
    if(!SRNameCode(SRModelName(model(object))) %in% seq(1,6))
      stop(paste("FLSR model (", SRNameCode(SRModelName(model(object))),
        ")in FLBRP object can not be used by brp. See ?ab"))

    .Call('stock_n', object, SRNameCode(SRModelName(object@model)),
              FLQuant(c(params(object)),dimnames=dimnames(params(object))))
  }
) # }}}

# catch.n {{{
setMethod('catch.n', signature(object='FLBRP'),
  function(object) {
    res <- landings.n(object) + discards.n(object)
    if (units(discards.n(object)) == units(landings.n(object)))
		  units(res) <- units(discards.n(object))
    else
      warning("unts of discards.n and landings.n do not match")
      
    return(res)
  }
) # }}}

# catch.wt {{{
setMethod('catch.wt', signature(object='FLBRP'),
  function(object) {

      denom<-landings.sel(object) + discards.sel(object)
      denom[denom==0]<-1
      
      res <- (landings.wt(object) * landings.sel(object) +
              discards.wt(object) * discards.sel(object)) / denom

    test=units(discards.wt(object)) == units(landings.wt(object))
    if (!is.na(test))  
    if (test)
				units(res) <- units(discards.wt(object))

    return(res)
  }
) # }}}

# catch.sel {{{
setMethod('catch.sel', signature(object='FLBRP'),
  function(object) {
    return(landings.sel(object) + discards.sel(object))
  }) # }}}

# catch.obs {{{
setMethod('catch.obs', signature(object='FLBRP'),
  function(object) {
    return(discards.obs(object)+landings.obs(object))
  }) # }}}

# biomass.obs {{{
setMethod('biomass.obs', signature(object='FLBRP'),
  function(object) {
    return(stock.obs(object))
  }) # }}}

# yield.obs {{{
setMethod('yield.obs', signature(object='FLBRP'),
  function(object) {
    return(landings.obs(object))
  }) # }}}

# stock {{{
setMethod('stock', signature(object='FLBRP'),
  function(object) {
		return(quantSums(stock.n(object) %*% stock.wt(object)))
  }) # }}}

# rec {{{
setMethod('rec', signature(object='FLBRP'),
  function(object) {
    return(stock.n(object)[1,])
  }) # }}}

# harvest {{{
setMethod("harvest", signature(object="FLBRP", catch="missing"),
	function(object){
    
    # selectivity
    sel <- expand(landings.sel(object) + discards.sel(object),
      year=dims(discards.sel(object))$minyear+(1:dim(fbar(object))[2]) - 1)
    dmns <- dimnames(sel)
    dmns$year <- dimnames(fbar(object))$year
    sel <- FLQuant(sel, dimnames=dmns)
    
    sel[,] <- sel[,1]
    sel <- sel %*% fbar(object)
    
    units(sel) <- "f"
    
    return(sel)
  }) # }}}

# ypr {{{
setMethod('ypr', signature(object='FLBRP'),
  function(object)
  {
    params(object)<-FLPar(1)
    model( object)<-formula(rec~a)
    
    # check model is supported by brp
    if(!SRNameCode(SRModelName(model(object))) %in% seq(1,6))
      stop(paste("FLSR model (", SRNameCode(SRModelName(model(object))),
        ")in FLBRP object can not be used by brp. See ?ab"))

    res<-.Call("ypr", object, SRNameCode(SRModelName(object@model)),
      FLQuant(c(params(object)),dimnames=dimnames(params(object))),
      PACKAGE = "FLBRP")

    return(res)
  }) # }}}

# hcrYield {{{
setMethod('hcrYield', signature(object='FLBRP', fbar='FLQuant'),
  function(object, fbar)
  {
    # check model is supported by brp
    if(!SRNameCode(SRModelName(model(object))) %in% seq(1,6))
      stop(paste("FLSR model (", SRNameCode(SRModelName(model(object))),
        ")in FLBRP object can not be used by brp. See ?ab"))

    # check input fbar dims
    if(!identical(dim(fbar), dim(fbar(object))))
      stop("input fbar must be the same length as fbar(object)")

    if(dims(object)$iter!=1 && dims(object@params)$iter ==1)
       m(object)<-propagate(m(object),iter=dims(params(object))$iter)
    else if (dims(object)$iter!=1 && dims(object@params)$iter !=1)
       if (dims(object)$iter!= dims(object@params)$iter)
          stop("Iters in params don't match")

    res <- .Call("hcrYield", object, SRNameCode(SRModelName(object@model)),
      FLQuant(c(params(object)),dimnames=dimnames(params(object))),
      fbar, PACKAGE = "FLBRP")
    
    # propagate landings.wt
    if(dims(res)$iter != dims(landings.wt(object))$iter)
      landings.wt(object) <- propagate(landings.wt(object), dims(res)$iter)

    return(quantSums(res %*% landings.wt(object)))
   }
)
setMethod('hcrYield', signature(object='FLBRP', fbar='numeric'),
  function(object, fbar)
    hcrYield(object, FLQuant(fbar)))
# }}}

# ssb {{{
setMethod('ssb', signature(object='FLBRP'),
  function(object) {

    f <- harvest(object) %*% harvest.spwn(object)
    m <- m(object) %*% m.spwn(object)
    
    expZ <- exp(-f %-% m)

    res <- quantSums(stock.n(object) %*% expZ %*% stock.wt(object) %*%
      mat(object))

    return(res)
  }
)# }}}

# landings {{{
setMethod('landings', signature(object='FLBRP'),
  function(object){
    return(quantSums(landings.n(object) %*% landings.wt(object)))
  }
) # }}}

# discards {{{
setMethod('discards', signature(object='FLBRP'),
  function(object) {
    return(quantSums(discards.n(object) %*% discards.wt(object)))
  }
) # }}}

# catch {{{
setMethod('catch', signature(object='FLBRP'),
  function(object) {
    return(landings(object) + discards(object))
  }
) # }}}

# revenue {{{
setMethod('revenue', signature(object='FLBRP'),
  function(object) {
    return(quantSums(landings.n(object) %*% landings.wt(object) %*% price(object)))
  }
) # }}}

# cost {{{
setMethod('cost', signature(object='FLBRP'),
  function(object){
    return(quantSums(FLCore::`%+%`(fbar(object) %*% vcost(object), fcost(object))))
    # return(quantSums((fbar(object) %*% vcost(object)) %+% fcost(object)))
  }
) # }}}

# profit {{{
setMethod('profit', signature(object='FLBRP'),
  function(object) {
    return(revenue(object) - cost(object))
  }
) # }}}

# msyRange {{{

#' @title MSY range
#' 
#' @description 
#' Calculates the values of fishing mortality, biomass, SSB etc. for a range of yields either side of MSY. 
#' 
#' @param object \code{FLBRP}
#' @param range the values of yield around MSY 
#' 
#' @return object of class \code{FLPar} with reference point quantities
#' 
#' @docType methods
#' @rdname msyrange
#' 
#' @seealso \code{\link{refpts}} 
#' 
#' @examples
#' data(ple4brp)
#' 
#' msyRange(ple4brp)

setMethod("msyRange", signature(object="FLBRP"),
  function(object, range=0.10) {

    refpts(object) <- FLPar(NA,
      dimnames=list(refpt=c("msy","min","max"),
      quantity=c("harvest","yield","rec","ssb","biomass","revenue","cost","profit"),
      iter=1))

    object <- brp(object)

    refpts(object)["min","yield"] <- refpts(object)["msy","yield"] * (1-range)
    
    refpts(object)["max","yield"] <- refpts(object)["msy","yield"] * (1-range)
     
    fn <- function(f,target,obj) {
      
      refpts(obj) <- FLPar(c(f, rep(NA,7)),
        dimnames=list(refpt=c("f"),
        quantity=c("harvest","yield","rec","ssb","biomass","revenue","cost","profit"),
        iter =1))
     
     return((refpts(brp(obj))[,"yield"]- target) ^ 2)
    }
     
    for (i in dimnames(refpts(object))$iter) {

      refpts(object)["min", "harvest", i] <- optimise(fn,
        c(0.01, refpts(object)["msy", "harvest",i]),
        target=refpts(object)["min", "yield"],
        obj=object, tol=.Machine$double.eps^0.5)$minimum

      refpts(object)["max", "harvest", i] <- optimise(fn,
        c(1, 10) * c(refpts(object)["msy", "harvest",i]),
        target=refpts(object)["max", "yield"], obj=object,
        tol=.Machine$double.eps^0.5)$minimum
    }
  
    refpts(brp(object))
  }
) # }}}

# r {{{

#' @title Intrisic rate of increase
#' 
#' @description 
#' Calculates the value of *r*, the intrisic rate of increase. 
#' 
#' @param m An object of class `FLBRP`
#' 
#' @return object of class \code{FLQuant} with *r* estimate
#' 
#' @docType methods
#' @rdname r
#' 
#' @seealso [FLCore::r()] 
#' 
#' @examples
#' data(ple4brp)
#'
#' r(ple4brp)

setMethod("r", signature(m="FLBRP", fec="missing"),
	function(m, by = 'year', method = 'el',...)
    do.call('r', list(m=m(m), fec=mat(m), by=by, method=method)))
# }}}

# sp {{{

#' @title Surplus production
#' 
#' @description 
#' Calculates the surplus production. 
#' 
#' @param m An object of class `FLBRP`
#' 
#' @return object of class \code{FLQuant} with *sp* estimate
#' 
#' @docType methods
#' @rdname sp
#' 
#' @seealso [FLCore::sp()] 
#' 
#' @examples
#' data(ple4brp)
#'
#' sp(ple4brp)

setMethod('sp', signature(stock='FLBRP', catch='missing'),
	function(stock, rel=TRUE)
    return(sp(ssb.obs(stock), catch.obs(stock), rel=rel)))
# }}}

# computeRefpts {{{

#' @rdname brp
#' @description To directly obtain the recalculated `refpts` slot of an `FLBRP` object, the
#' `computeRefpts` method can be used. This is equivalent to *fitting* the object
#' using `brp` and then extracting the `@refpts` slot.
#' @examples
#' m(ple4brp)[1:3,] <- 0.2
#' computeRefpts(ple4brp)

setMethod('computeRefpts', signature(object='FLBRP'), function(object){
	refpts(brp(object))})

# }}}
