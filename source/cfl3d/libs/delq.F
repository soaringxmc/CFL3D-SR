c  ---------------------------------------------------------------------------
c  CFL3D is a structured-grid, cell-centered, upwind-biased, Reynolds-averaged
c  Navier-Stokes (RANS) code. It can be run in parallel on multiple grid zones
c  with point-matched, patched, overset, or embedded connectivities. Both
c  multigrid and mesh sequencing are available in time-accurate or
c  steady-state modes.
c
c  Copyright 2001 United States Government as represented by the Administrator
c  of the National Aeronautics and Space Administration. All Rights Reserved.
c 
c  The CFL3D platform is licensed under the Apache License, Version 2.0 
c  (the "License"); you may not use this file except in compliance with the 
c  License. You may obtain a copy of the License at 
c  http://www.apache.org/licenses/LICENSE-2.0. 
c 
c  Unless required by applicable law or agreed to in writing, software 
c  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT 
c  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the 
c  License for the specific language governing permissions and limitations 
c  under the License.
c  ---------------------------------------------------------------------------
c
      subroutine delq(jdim,kdim,idim,q,sj,sk,si,vol,dp,wt,blank,iover,
     .                qj0,qk0,qi0,bcj,bck,bci,nbl,volj0,volk0,voli0,
     .                maxbl,vormax,ivmax,jvmax,kvmax,ldim)
c
c     $Id$
c
c**********************************************************************
c     Purpose:  Evaluate derivatives of a scalar in q at cell centers
c**********************************************************************
c
c      input arrays   : 
c       q             : primitive variables at cell centers
c                       (rho,u,v,w,p)
c       vol           : cell volumes
c       sj,sk,si      : metrics
c                       direction cosine, area, speed of cell face
c       ifj,ifk,ifi   : =0 don't compute contribution from that direction
c                       >0 do      "
c      output arrays  :
c       dp            : derivatives
c                       1 = dpdx
c                       2 = dpdy
c                       3 = dpdz
c      scratch arrays :
c       wt(1-3)       : cross-flow temporaries
c
c**********************************************************************
c
#   ifdef CMPLX
      implicit complex(a-h,o-z)
#   endif
c
      dimension q(jdim,kdim,idim,5),dp(jdim-1,kdim-1,idim-1,3)
      dimension sj(jdim,kdim,idim-1,5),sk(jdim,kdim,idim-1,5),
     .          si(jdim,kdim,idim,5)
      dimension vol(jdim,kdim,idim-1),blank(jdim,kdim,idim)
      dimension wt(jdim,kdim,9)
      dimension bcj(kdim,idim-1,2),bck(jdim,idim-1,2),bci(jdim,kdim,2)
      dimension qj0(kdim,idim-1,5,4),
     .          qk0(jdim,idim-1,5,4),qi0(jdim,kdim,5,4)
      dimension volj0(kdim,idim-1,4),
     .          volk0(jdim,idim-1,4),voli0(jdim,kdim,4)
      dimension vormax(maxbl),ivmax(maxbl),jvmax(maxbl),kvmax(maxbl)
c
      common /twod/ i2d
c
      ifi=1
      ifj=1
      ifk=1
      jdim1 = jdim-1
      kdim1 = kdim-1
      idim1 = idim-1
      do 999 l=1,3
      do 999 i=1,idim1
      do 999 k=1,kdim1
      do 999 j=1,jdim1
        dp(j,k,i,l) = 0.
 999  continue
      onec = 1.
c
c      J-direction contributions
c
      if(ifj .gt. 0) then
      do 1000 i=1,idim1
      do 1000 k=1,kdim1
c
c      cycle through interfaces
c
      do 100 j=2,jdim1
      term      = sj(j,k,i,4)/(vol(j,k,i)+vol(j-1,k,i))
      wt(j,1,1) = term*((q(j,k,i,ldim)-q(j-1,k,i,ldim))*sj(j,k,i,1))
      wt(j,1,2) = term*((q(j,k,i,ldim)-q(j-1,k,i,ldim))*sj(j,k,i,2))
      wt(j,1,3) = term*((q(j,k,i,ldim)-q(j-1,k,i,ldim))*sj(j,k,i,3))
  100 continue
      j=1
      jp1=min(jdim-1,j+1)
      term      = sj(j,k,i,4)/(volj0(k,i,1)+vol(j,k,i))
      factor    = bcj(k,i,1) + 1.0
      term = term*factor
      wt(j,1,1) = term*((q(j,k,i,ldim)-qj0(k,i,ldim,1))*sj(j,k,i,1))
      wt(j,1,2) = term*((q(j,k,i,ldim)-qj0(k,i,ldim,1))*sj(j,k,i,2))
      wt(j,1,3) = term*((q(j,k,i,ldim)-qj0(k,i,ldim,1))*sj(j,k,i,3))
      j=jdim
      jm2=max(1,j-2)
      term      = sj(j,k,i,4)/(volj0(k,i,3)+vol(j-1,k,i))
      factor    = bcj(k,i,2) + 1.0
      term = term*factor
      wt(j,1,1) = term*((qj0(k,i,ldim,3)-q(j-1,k,i,ldim))*sj(j,k,i,1))
      wt(j,1,2) = term*((qj0(k,i,ldim,3)-q(j-1,k,i,ldim))*sj(j,k,i,2))
      wt(j,1,3) = term*((qj0(k,i,ldim,3)-q(j-1,k,i,ldim))*sj(j,k,i,3))
c
c      cycle through cell centers
c
      do 200 l=1,3
      do 200 j=1,jdim1
      dp(j,k,i,l)   = dp(j,k,i,l) + wt(j,1,l) + wt(j+1,1,l)
  200 continue
 1000 continue
      end if
c
c      K-direction contributions
c
      if(ifk .gt. 0) then
      do 2000 i=1,idim1
c
c      cycle through interfaces
c
      do 1200 k=2,kdim-1
      do 1200 j=1,jdim1
      term      = sk(j,k,i,4)/(vol(j,k,i)+vol(j,k-1,i))
      wt(j,k,1) = term*((q(j,k,i,ldim)-q(j,k-1,i,ldim))*sk(j,k,i,1))
      wt(j,k,2) = term*((q(j,k,i,ldim)-q(j,k-1,i,ldim))*sk(j,k,i,2))
      wt(j,k,3) = term*((q(j,k,i,ldim)-q(j,k-1,i,ldim))*sk(j,k,i,3))
 1200 continue
      k=1
      kp1=min(kdim-1,k+1)
      do 1201 j=1,jdim1
      term      = sk(j,k,i,4)/(volk0(j,i,1)+vol(j,k,i))
      factor    = bck(j,i,1) + 1.0
      term = term*factor
      wt(j,k,1) = term*((q(j,k,i,ldim)-qk0(j,i,ldim,1))*sk(j,k,i,1))
      wt(j,k,2) = term*((q(j,k,i,ldim)-qk0(j,i,ldim,1))*sk(j,k,i,2))
      wt(j,k,3) = term*((q(j,k,i,ldim)-qk0(j,i,ldim,1))*sk(j,k,i,3))
 1201 continue
      k=kdim
      km2=max(1,k-2)
      do 1202 j=1,jdim1
      term      = sk(j,k,i,4)/(volk0(j,i,3)+vol(j,k-1,i))
      factor    = bck(j,i,2) + 1.0
      term = term*factor
      wt(j,k,1) = term*((qk0(j,i,ldim,3)-q(j,k-1,i,ldim))*sk(j,k,i,1))
      wt(j,k,2) = term*((qk0(j,i,ldim,3)-q(j,k-1,i,ldim))*sk(j,k,i,2))
      wt(j,k,3) = term*((qk0(j,i,ldim,3)-q(j,k-1,i,ldim))*sk(j,k,i,3))
 1202 continue
c
c      cycle through cell centers
c
      do 1400 l=1,3
      do 1400 k=1,kdim1
      do 1400 j=1,jdim1
      dp(j,k,i,l) = dp(j,k,i,l) + wt(j,k,l) + wt(j,k+1,l)
 1400 continue
 2000 continue
      end if
c
c      I-direction contributions
c
      if(ifi .gt. 0) then
c      cycle through interfaces
c
      if(i2d .eq. 0) then
      do 1700 i=2,idim1
      do 1700 k=1,kdim1
      do 1700 j=1,jdim1
      term      = si(j,k,i,4)/(vol(j,k,i)+vol(j,k,i-1))
      wt(j,k,1) = term*((q(j,k,i,ldim)-q(j,k,i-1,ldim))*si(j,k,i,1))
      wt(j,k,2) = term*((q(j,k,i,ldim)-q(j,k,i-1,ldim))*si(j,k,i,2))
      wt(j,k,3) = term*((q(j,k,i,ldim)-q(j,k,i-1,ldim))*si(j,k,i,3))
c
      dp(j,k,i-1,1) = dp(j,k,i-1,1) + wt(j,k,1)
      dp(j,k,i-1,2) = dp(j,k,i-1,2) + wt(j,k,2)
      dp(j,k,i-1,3) = dp(j,k,i-1,3) + wt(j,k,3)
c
      dp(j,k,i,1) = dp(j,k,i,1) + wt(j,k,1)
      dp(j,k,i,2) = dp(j,k,i,2) + wt(j,k,2)
      dp(j,k,i,3) = dp(j,k,i,3) + wt(j,k,3)
 1700 continue
c
      ii=1
      iip1=min(idim-1,ii+1)
      do 1900 k=1,kdim1
      do 1900 j=1,jdim1
      term       = si(j,k,ii,4)/(voli0(j,k,1)+vol(j,k,ii))
      factor     = bci(j,k,1) + 1.0
      term = term*factor
      wt(j,k,1) = term*((q(j,k,ii,ldim)-qi0(j,k,ldim,1))*si(j,k,ii,1))
      wt(j,k,2) = term*((q(j,k,ii,ldim)-qi0(j,k,ldim,1))*si(j,k,ii,2))
      wt(j,k,3) = term*((q(j,k,ii,ldim)-qi0(j,k,ldim,1))*si(j,k,ii,3))
      dp(j,k,1,1) = dp(j,k,1,1) + wt(j,k,1)
      dp(j,k,1,2) = dp(j,k,1,2) + wt(j,k,2)
      dp(j,k,1,3) = dp(j,k,1,3) + wt(j,k,3)
 1900 continue
c
      ii=idim
      iim2=max(1,ii-2)
      do 2200 k=1,kdim1
      do 2200 j=1,jdim1
      term      = si(j,k,ii,4)/(voli0(j,k,3)+vol(j,k,ii-1))
      factor    = bci(j,k,2) + 1.0
      term = term*factor
      wt(j,k,1) = term*((qi0(j,k,ldim,3)-q(j,k,ii-1,ldim))*si(j,k,ii,1))
      wt(j,k,2) = term*((qi0(j,k,ldim,3)-q(j,k,ii-1,ldim))*si(j,k,ii,2))
      wt(j,k,3) = term*((qi0(j,k,ldim,3)-q(j,k,ii-1,ldim))*si(j,k,ii,3))
      
      dp(j,k,idim1,1) = dp(j,k,idim1,1) + wt(j,k,1)
      dp(j,k,idim1,2) = dp(j,k,idim1,2) + wt(j,k,2)
      dp(j,k,idim1,3) = dp(j,k,idim1,3) + wt(j,k,3)
 2200 continue
      end if
      end if
c
c     set velocity derivatives for hole cells to one
c
      if (iover.eq.1) then
         do 2403 nk=1,3
         do 2402 i=1,idim1
         do 2402 k=1,kdim1
         do 2402 j=1,jdim1
         dp(j,k,i,nk) = ccvmgt(onec,dp(j,k,i,nk),
     .                  (real(blank(j,k,i)).eq.0.e0))
 2402    continue
 2403    continue
      end if
c
      return
      end
