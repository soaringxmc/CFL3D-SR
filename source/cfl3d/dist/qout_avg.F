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
      subroutine qout_avg(iseq,lw,lw2,w,mgwk,wk,nwork,nplots,iovrlp,
     .                iibg,kkbg,jjbg,ibcg,lbg,ibpntsg,qb,lwdat,nbci0,
     .                nbcj0,nbck0,nbcidim,nbcjdim,nbckdim,jbcinfo,
     .                kbcinfo,ibcinfo,bcfilei,bcfilej,bcfilek,
     .                itrans,irotat,idefrm,nblock,levelg,igridg,iviscg,
     .                jdimg,kdimg,idimg,nblg,clw,ncycmax,nplot3d,
     .                inpl3d,ip3dsurf,nprint,inpr,iadvance,mycomm,
     .                myid,myhost,mblk2nd,nou,bou,nbuf,ibufdim,maxbl,
     .                maxgr,maxseg,iitot,jsg,ksg,isg,jeg,keg,ieg,
     .                ninter,windex,iindex,nblkpt,intmax,nsub1,maxxe,
     .                nblk,nbli,limblk,isva,nblon,mxbli,thetay,
     .                ip3ddim,nmap,iwk,iwork,xorig,yorig,zorig,
     .                period_miss,geom_miss,epsc0,epsrot,isav_blk,
     .                isav_pat,isav_pat_b,isav_emb,isav_prd,
     .                lbcprd,lbcemb,
     .                dthetxx,dthetyy,dthetzz,nblcg,lfgm,istat2_bl,
     .                istat2_pa,istat2_pe,istat2_em,istat_size,
     .                vormax,ivmax,jvmax,kvmax,bcfiles,mxbcfil,iprnsurf,
     .                nt,movabs,nummem,nvdsp,maxsw,nsw,iswinfo)
c
c     $Id$
c
c***********************************************************************
c     Purpose:  Output data for plotting or printing.
c               lhdr = -1  avggp
c               lhdr =  0  plot3d_avg (field and surface solutions)
c               lhdr =  1  plot3d_avg + dumping to cfl3d.out
c***********************************************************************
c
#   ifdef CMPLX
      implicit complex(a-h,o-z)
#   endif
#if defined DIST_MPI
#     include "mpif.h"
#   ifdef DBLE_PRECSN
#     define MY_MPI_REAL MPI_DOUBLE_PRECISION
#   else
#     define MY_MPI_REAL MPI_REAL
#   endif
#endif
c
c     maxbl   - maximum number of blocks
c     maxgr   - maximum number of grids
c     nplots  - maximum number of data sets to output via PLOT3D or print
c     ncycmax - maximum number of time-steps/cycles
c
      character*80  bcfiles(mxbcfil)
      character*120 bou(ibufdim,nbuf)
c
      integer bcfilei,bcfilej,bcfilek
c
      dimension nou(nbuf)
      dimension istat2_bl(istat_size,mxbli*5),
     .          istat2_pa(istat_size,intmax*nsub1*3),
     .          istat2_em(istat_size,lbcemb*3),
     .          istat2_pe(istat_size,lbcprd*5)
      dimension vormax(maxbl),ivmax(maxbl),jvmax(maxbl),kvmax(maxbl)
      dimension w(mgwk),wk(nwork),lw(80,maxbl),lwdat(maxbl,maxseg,6)
      dimension nmap(maxbl),mblk2nd(maxbl),iwk(iwork),lw2(43,maxbl)
      dimension iovrlp(maxbl),iibg(iitot),kkbg(iitot),jjbg(iitot),
     .          ibcg(iitot),lbg(maxbl),ibpntsg(maxbl,4),qb(iitot,5,3)
      dimension nbci0(maxbl),nbcidim(maxbl),nbcj0(maxbl),nbcjdim(maxbl),
     .          nbck0(maxbl),nbckdim(maxbl),ibcinfo(maxbl,maxseg,7,2),
     .          jbcinfo(maxbl,maxseg,7,2),kbcinfo(maxbl,maxseg,7,2),
     .          bcfilei(maxbl,maxseg,2),bcfilej(maxbl,maxseg,2),
     .          bcfilek(maxbl,maxseg,2)
      dimension itrans(maxbl),irotat(maxbl),levelg(maxbl),igridg(maxbl),
     .          iviscg(maxbl,3),jdimg(maxbl),kdimg(maxbl),idimg(maxbl),
     .          nblcg(maxbl),nblg(maxgr),clw(ncycmax),inpl3d(nplots,11),
     .          inpr(nplots,11),iadvance(maxbl),thetay(maxbl),
     .          idefrm(maxbl),iswinfo(maxsw,11)
      dimension jsg(maxbl),ksg(maxbl),isg(maxbl),jeg(maxbl),keg(maxbl),
     .          ieg(maxbl)
      dimension windex(maxxe,2),iindex(intmax,6*nsub1+9),nblkpt(maxxe)
      dimension dthetxx(intmax,nsub1),dthetyy(intmax,nsub1),
     .          dthetzz(intmax,nsub1)
      dimension nblk(2,mxbli),limblk(2,6,mxbli),isva(2,2,mxbli),
     .          nblon(mxbli)
      dimension geom_miss(2*mxbli),period_miss(lbcprd)
      dimension isav_prd(lbcprd,12)
      dimension isav_blk(2*mxbli,17)
      dimension isav_emb(lbcemb,12)
      dimension isav_pat(intmax,17),isav_pat_b(intmax,nsub1,6)
      dimension xorig(maxbl),yorig(maxbl),zorig(maxbl)
      dimension ip3ddim(3,nplots)
c
      common /bin/ ibin,iblnk,iblnkfr,ip3dgrad
      common /ginfo/ jdim,kdim,idim,jj2,kk2,ii2,nblc,js,ks,is,je,ke,ie,
     .        lq,lqj0,lqk0,lqi0,lsj,lsk,lsi,lvol,ldtj,lx,ly,lz,lvis,
     .        lsnk0,lsni0,lq1,lqr,lblk,lxib,lsig,lsqtq,lg,
     .        ltj0,ltk0,lti0,lxkb,lnbl,lvj0,lvk0,lvi0,lbcj,lbck,lbci,
     .        lqc0,ldqc0,lxtbi,lxtbj,lxtbk,latbi,latbj,latbk,
     .        lbcdj,lbcdk,lbcdi,lxib2,lux,lcmuv,lvolj0,lvolk0,lvoli0,
     .        lxmdj,lxmdk,lxmdi,lvelg,ldeltj,ldeltk,ldelti,
     .        lxnm2,lynm2,lznm2,lxnm1,lynm1,lznm1,lqavg
      common /ginfo2/ lq2avg,iskip_blocks,inc_2d(3),inc_coarse(3),
     .        lqsavg,lqs2avg,lvdsp,lvdj0,lvdk0,lvdi0,lvdavg,lvd2avg,
     .        lvsj0,lvsjdim,lvsk0,lvskdim,lvsi0,lvsidim
      common /info/ title(20),rkap(3),xmach,alpha,beta,dt,fmax,nit,ntt,
     .        idiag(3),nitfo,iflagts,iflim(3),nres,levelb(5),mgflag,
     .        iconsf,mseq,ncyc1(5),levelt(5),nitfo1(5),ngam,nsm(5),iipv
      common /maxiv/ ivmx
      common /mgrd/ levt,kode,mode,ncyc,mtt,icyc,level,lglobal
      common /reyue/ reue,tinf,ivisc(3)
      common /twod/ i2d
      common /unst/ time,cfltau,ntstep,ita,iunst,cfltau0,cfltauMax
      common /moov/movie,nframes,icall1,lhdr,icoarsemovie,i2dmovie,
     .        icallsf
      common /conversion/ radtodeg
      common /avgdata/ xnumavg,iteravg,xnumavg2,ipertavg,npertavg,
     .      iclcd,isubit_r,icallavg
      common /plot3dtyp/ ifunct
      common /memry/ lowmem_ux
c
      allocatable :: iprdim(:,:)
c
c***********************************************************************
c     write output file in PLOT3D format
c     in this routine, iptype = inpl3d(n,2), where n is the block number 
c     iptype = 0...output q at grid points 
c              1...output q cell centers 
c              2...turbulence data at cell centers, output in place of
c                  the standard plot3d q vector 
c              3...smin at cell centers 
c              4...vist3d at cell centers 
c              5...cp at cell centers 
c             -5...cp at grid points 
c              6...p/pinf at cell centers 
c             -6...p/pinf at grid points 
c***********************************************************************
c
      if (lhdr.eq.-1) then
      if (nplot3d.gt.0 .or. nprint.gt.0 .or. 
     .    iteravg.gt.0) then    
c
c        update all bc's for level lglobal (and above, if embeded),
c        even if not all blocks at that level get output to plot3d or
c        printout files - this is different from older versions of the
c        code, in which bc's are only called if needed to get the latest
c        values for output.
c
         level_sav = level
         lglobal = lfgm-(mseq-iseq)
c
         do level=lglobal,levelt(iseq)
c

            if (iipv.gt.0) then
               nttuse=max(ntt-1,1)
               clwuse = clw(nttuse)
            end if

#if defined(DIST_MPI)
            call MPI_Bcast(clwuse,1,MY_MPI_REAL,myhost,
     .                     mycomm,ierr)
            if (myid.ne.myhost) then
c
#endif
            do nbl=1,nblock
c              need to call even for blocks not advanced
               if (level.eq.levelg(nbl)) then
                  if (mblk2nd(nbl).eq.myid) then
                     call lead(nbl,lw,lw2,maxbl)
                     call bc(1,nbl,lw,lw2,w,mgwk,wk,nwork,
     .                       clwuse,nou,bou,nbuf,ibufdim,maxbl,
     .                       maxgr,maxseg,itrans,irotat,idefrm,
     .                       igridg,nblg,nbci0,nbcj0,nbck0,nbcidim,
     .                       nbcjdim,nbckdim,ibcinfo,jbcinfo,
     .                       kbcinfo,bcfilei,bcfilej,bcfilek,
     .                       lwdat,myid,idimg,jdimg,kdimg,bcfiles,
     .                       mxbcfil,nummem)
                  end if
               end if
            end do
c
c           update periodic boundary conditions
c
            lres   = 1
            nsafe  = nwork-lres+1
            mneed  = lbcprd*5
            iwk1   = 1
            iwk2   = iwk1 + mneed
            iwk3   = iwk2 + mneed
            iwk4   = iwk3 + mneed
            iwk5   = iwk4 + mneed*2
            iwk6   = iwk5 + mneed
            iwork1 = iwork - iwk6
            if (iwork1.lt.0) then
               nou(1) = min(nou(1)+1,ibufdim)
               write(bou(nou(1),1),'(''stopping...not enough integer '',
     .                        ''work space for subroutine bc_period'')')
               nou(1) = min(nou(1)+1,ibufdim)
               write(bou(nou(1),1),'(''have, need = '',2i12)') 
     .         iwork,iwk6
               call termn8(myid,-1,ibufdim,nbuf,bou,nou)
            end if
            do iii = 1,iwk6
               iwk(iii) = 0
            end do
            call bc_period(1,nbl,lw,lw2,w,mgwk,wk(lres),nsafe,maxbl,
     .                     maxgr,maxseg,iadvance,bcfilei,bcfilej,
     .                     bcfilek,lwdat,xorig,yorig,zorig,jdimg,kdimg,
     .                     idimg,lbcprd,isav_prd,
     .                     period_miss,epsrot,iwk(iwk1),iwk(iwk2),
     .                     iwk(iwk3),iwk(iwk4),iwk(iwk5),myid,myhost,
     .                     mycomm,mblk2nd,nou,bou,nbuf,ibufdim,
     .                     istat2_pe,istat_size,bcfiles,mxbcfil,nummem)
c
c           update embeded-grid boundary conditions
c
            lres   = 1
            nsafe  = nwork-lres+1
            mneed  = lbcemb*3
            iwk1   = 1
            iwk2   = iwk1 + mneed
            iwk3   = iwk2 + mneed
            iwk4   = iwk3 + mneed
            iwk5   = iwk4 + mneed*2
            iwk6   = iwk5 + mneed
            iwork1 = iwork - iwk6
            if (iwork1.lt.0) then
               nou(1) = min(nou(1)+1,ibufdim)
               write(bou(nou(1),1),'(''stopping...not enough integer '',
     .                        ''work space for subroutine bc_embed'')')
               nou(1) = min(nou(1)+1,ibufdim)
               write(bou(nou(1),1),'(''have, need = '',2i12)')
     .         iwork,iwk6
               call termn8(myid,-1,ibufdim,nbuf,bou,nou)
            end if
            do iii = 1,iwk6
               iwk(iii) = 0
            end do
            call bc_embed(1,nbl,lw,lw2,w,mgwk,wk(lres),nsafe,maxbl,
     .                    maxgr,lbcemb,iadvance,idimg,jdimg,
     .                    kdimg,isav_emb,iwk(iwk1),
     .                    iwk(iwk2),iwk(iwk3),iwk(iwk4),iwk(iwk5),
     .                    myid,myhost,mycomm,mblk2nd,nou,bou,nbuf,
     .                    ibufdim,iviscg,istat2_em,istat_size,nummem)
c
c           update 1-1 block boundary conditions
c
            lres   = 1
            nsafe  = nwork-lres+1
            mneed  = mxbli*5
            iwk1   = 1
            iwk2   = iwk1 + mneed
            iwk3   = iwk2 + mneed
            iwk4   = iwk3 + mneed
            iwk5   = iwk4 + mneed*2
            iwk6   = iwk5 + mneed
            iwork1 = iwork - iwk6
            if (iwork1.lt.0) then
               nou(1) = min(nou(1)+1,ibufdim)
               write(bou(nou(1),1),'(''stopping...not enough integer '',
     .                        ''work space for subroutine bc_blkint'')')
               nou(1) = min(nou(1)+1,ibufdim)
               write(bou(nou(1),1),'(''have, need = '',2i12)')
     .         iwork,iwk6
               call termn8(myid,-1,ibufdim,nbuf,bou,nou)
            end if
            do iii = 1,iwk6
               iwk(iii) = 0
            end do
            call bc_blkint(1,nbl,lw,lw2,w,mgwk,wk(lres),nsafe,maxbl,
     .                     maxgr,mxbli,iadvance,geom_miss,epsc0,nblk,
     .                     nbli,limblk,isva,nblon,jdimg,kdimg,idimg,
     .                     mblk2nd,isav_blk,iwk(iwk1),
     .                     iwk(iwk2),iwk(iwk3),iwk(iwk4),iwk(iwk5),
     .                     nou,bou,nbuf,ibufdim,myid,myhost,mycomm,
     .                     istat2_bl,istat_size,nummem)
c
c           update patch-grid boundary conditions
c
            lres   = 1
            nsafe  = nwork-lres+1
            mneed  = intmax*nsub1*3
            iwk1   = 1
            iwk2   = iwk1 + mneed
            iwk3   = iwk2 + mneed
            iwk4   = iwk3 + mneed
            iwk5   = iwk4 + mneed*2
            iwk6   = iwk5 + mneed*2
            iwork1 = iwork - iwk6
            if (iwork1.lt.0) then
               nou(1) = min(nou(1)+1,ibufdim)
               write(bou(nou(1),1),'(''stopping...not enough integer'',
     .                       '' work space for subroutine bc_patch'')')
               nou(1) = min(nou(1)+1,ibufdim)
               write(bou(nou(1),1),'(''have, need = '',2i12)')
     .         iwork,iwk6
               call termn8(myid,-1,ibufdim,nbuf,bou,nou)
            end if
            do iii = 1,iwk6
               iwk(iii) = 0
            end do
            call bc_patch(1,nbl,lw,lw2,w,mgwk,wk(lres),nsafe,maxbl,
     .                    maxgr,intmax,nsub1,maxxe,iadvance,jdimg,kdimg,
     .                    idimg,ninter,windex,iindex,nblkpt,dthetxx,
     .                    dthetyy,dthetzz,isav_pat,isav_pat_b,
     .                    iwk(iwk1),iwk(iwk2),iwk(iwk3),
     .                    iwk(iwk4),iwk(iwk5),myid,myhost,mycomm,
     .                    mblk2nd,nou,bou,nbuf,ibufdim,
     .                    istat2_pa,istat_size,nummem)
c
c           update chimera boundary conditions
c
c           don't update interior (fringe) points if cell center data 
c           is to be output (this is needed to get cell center output
c           identical to version 5)
c
            int_updt = 1
            do n=1,nplot3d
               if (inpl3d(n,2).gt.0) then
                  int_updt = 0
               end if
            end do
c
            do nbl=1,nblock
               if (iadvance(nbl).ge.0) then
                  if (level.eq.levelg(nbl)) then
                     if (mblk2nd(nbl).eq.myid) then
                        call lead(nbl,lw,lw2,maxbl)
                        lres  = 1
                        nsafe = nwork-lres+1
                        call bc_xmera(1,nbl,lw,lw2,w,mgwk,wk(lres),
     .                                nsafe,maxbl,iitot,iviscg,iovrlp,
     .                                lbg,ibpntsg,qb,iibg,kkbg,jjbg,
     .                                ibcg,nou,bou,nbuf,ibufdim,
     .                                int_updt,nummem)
                     end if
                  end if
               end if
            end do
c
c           compute gradient-based variables vorticity, invariant q0, gradrho, gradp
c           and install them in vdsp
c     
            do nbl=1,nblock
               if (level.eq.levelg(nbl)) then
                  if (mblk2nd(nbl).eq.myid) then
                     call lead(nbl,lw,lw2,maxbl)
                     ipwk  = 1
                     irwk  = ipwk + (jdim-1)*(kdim-1)*(idim-1)*3
                     ibwk3 = irwk + (jdim-1)*(kdim-1)*(idim-1)*3
                     nroom=nwork-(ibwk3+jdim*kdim*9)
                     if (nroom .lt. 0.) then
                        if (myid.eq.myhost) then
                           write(11,'('' not enough memory vargrad'')')
                           write(11,'('' have, need = '',2i12)') nwork,
     .                     nwork-nroom
                           write(11,'('' not computing vargrad'')')
                        end if
                     else
                        call vargrad(jdim,kdim,idim,w(lq),w(lsj),w(lsk),
     .                              w(lsi),w(lvol),w(lux),wk(ibwk3),
     .                              w(lblk),iovrlp(nbl),w(lqj0),w(lqk0),
     .                              w(lqi0),w(lbcj),w(lbck),w(lbci),nbl,
     .                              w(lvolj0),w(lvolk0),w(lvoli0),maxbl,
     .                              vormax,ivmax,jvmax,kvmax,wk(ipwk),
     .                              wk(irwk),w(lvdsp),nvdsp)
                     end if
                  end if
               end if
            end do
c
c           install ghost values in vdj0,vdk0,vdi0 to obtain vdsp at grid points
c
            do nbl=1,nblock
               if (level.eq.levelg(nbl)) then
                  if (mblk2nd(nbl).eq.myid) then
                     call lead(nbl,lw,lw2,maxbl)
                     ldim = nvdsp
                     call bc_vdsp(jdim,kdim,idim,w(lvdsp),w(lvdj0),
     .                            w(lvdk0),w(lvdi0),w(lbcj),w(lbck),
     .                            w(lbci),w(lblk),ldim)
                  end if
               end if
            end do
c
c           call qface to install face-center values in
c           the qi0/qj0/qk0 arrays
c
            do nbl=1,nblock
               if (level.eq.levelg(nbl)) then
                  if (mblk2nd(nbl).eq.myid) then
                     call lead(nbl,lw,lw2,maxbl)
                     ldim = 5
                     call qface(jdim,kdim,idim,w(lq),w(lqj0),
     .                          w(lqk0),w(lqi0),w(lbcj),w(lbck),
     .                          w(lbci),w(lblk),ldim)
                     if (ivmx.ge.2) then
c                    turbulent viscosity
                        ldim = 1
                        call qface(jdim,kdim,idim,w(lvis),w(lvj0),
     .                             w(lvk0),w(lvi0),w(lbcj),w(lbck),
     .                             w(lbci),w(lblk),ldim)
c                    turbulence quantities
                        ldim = nummem
                        call qface(jdim,kdim,idim,w(lxib),w(ltj0),
     .                             w(ltk0),w(lti0),w(lbcj),w(lbck),
     .                             w(lbci),w(lblk),ldim)
                     end if
c                    vdsp quantities
                     ldim = nvdsp
                     call qface(jdim,kdim,idim,w(lvdsp),w(lvdj0),
     .                          w(lvdk0),w(lvdi0),w(lbcj),w(lbck),
     .                          w(lbci),w(lblk),ldim)
                  end if
               end if
            end do
c
#if defined(DIST_MPI)
            end if
c
#endif
         end do
c
         level = level_sav
c
      end if
c 
c---- modification for averaging at grid points ------------------------------                                             
c
c     average field solutions
c
        do 999 n = 1,nblock                            
          nbl = n
          if (level.ne.levelg(nbl)) go to 999 
          if (mblk2nd(nbl).eq.myid) then
c
            call lead(nbl,lw,lw2,maxbl)
c
            i1 = 1
            i2 = idim
            i3 = 1                                                      
            j1 = 1                                                      
            j2 = jdim                                                   
            j3 = 1                                                      
            k1 = 1                                                      
            k2 = kdim                           
            k3 = 1                                                
c
            jdw = (j2-j1)/j3 + 1                                        
            kdw = (k2-k1)/k3 + 1                                        
            idw = (i2-i1)/i3 + 1                            

            if( -2.eq.-2 ) then
c           average values at grid points
            ixwk = 1
            ifuncdim = max(5,ifunct)
            ibwk = ixwk + jdw*kdw*idw*ifuncdim
            ixgk = ibwk + jdim*kdim*idim*2
            ixvk = ixgk + jdw*kdw*idw*4                              
            nroom = nwork - (ixvk+jdw*kdw*idw*ifuncdim-1)
            if (nroom .lt. 0.) then
               if (myid.eq.myhost) then
                  write(11,'('' not enough memory for avggp'')')
                  write(11,'('' have, need = '',2i12)') nwork,
     .            nwork-nroom
                  write(11,'('' Aborting - not calling avggp'')')
#if defined DIST_MPI
                  call MPI_ABORT(MPI_COMM_WORLD, myid, mpierror)
#else
                  stop
#endif
               end if                                                   
            else              
               iflag = 1
               call avggp(jdim,kdim,idim,
     .                    i1,i2,i3,j1,j2,j3,k1,k2,k3,
     .                    w(lq),w(lqi0),w(lqj0),w(lqk0),w(lx),
     .                    w(ly),w(lz),wk(ixwk),wk(ibwk),
     .                    w(lblk),wk(ixgk),iflag,w(lvis),iovrlp(nbl),
     .                    nbl,nmap,w(lbcj),w(lbck),w(lbci),
     .                    w(lvj0),w(lvk0),w(lvi0),ifunc,n,jdw,kdw,idw,
     .                    nplots,jdimg,kdimg,idimg,nblcg,jsg,ksg,isg,
     .                    jeg,keg,ieg,ninter,iindex,intmax,nsub1,
     .                    maxxe,nblk,nbli,limblk,isva,nblon,mxbli,
     .                    thetay,maxbl,maxgr,myid,myhost,mycomm,
     .                    mblk2nd,inpl3d,nblock,nblkpt,wk(ixvk),
     .                    w(lsj),w(lsk),w(lsi),w(lvol),nummem,
     .                    ifuncdim,w(lxib),w(ltj0),w(ltk0),w(lti0),
     .                    w(lvdsp),nvdsp,w(lvdj0),w(lvdk0),w(lvdi0),
     .                    w(lqavg),w(lq2avg),w(lqsavg),w(lqs2avg),
     .                    w(lvdavg),w(lvd2avg),w(lvsj0),w(lvsjdim),
     .                    w(lvsk0),w(lvskdim),w(lvsi0),w(lvsidim))
            end if 
            end if                                                  
c
         end if   !end of blk2nd(nbl).eq.myid or myid.eq.myhost if loop
 999    continue  !end of do loop over n=1,nblock
c
c     average surface solutions
c
      do 888 isw=1,nsw
        nbl = iswinfo(isw,1)
        if (level.ne.levelg(nbl)) go to 888
        if (mblk2nd(nbl).eq.myid) then
c
            call lead(nbl,lw,lw2,maxbl)
c
            i1 = iswinfo(isw,3)
            i2 = iswinfo(isw,4)
            i3 = 1
            j1 = iswinfo(isw,6)
            j2 = iswinfo(isw,7)
            j3 = 1
            k1 = iswinfo(isw,9)
            k2 = iswinfo(isw,10)
            k3 = 1
c
            jdw = (j2-j1)/j3 + 1
            kdw = (k2-k1)/k3 + 1
            idw = (i2-i1)/i3 + 1
c           average values at grid points
            ixwk = 1
            nset = 14
            ibwk = ixwk + jdw*kdw*idw*nset
            ixgk = ibwk + jdim*kdim*idim*2
            ixvk = ixgk + jdw*kdw*idw*4
            nroom = nwork - (ixvk+jdw*kdw*idw*nset-1)
            if (nroom .lt. 0.) then       
               if (myid.eq.myhost) then
                  write(11,'('' not enough memory for avggp'')')
                  write(11,'('' have, need = '',2i12)') nwork,
     .            nwork-nroom
                  write(11,'('' Aborting - not calling avggp'')')
#if defined DIST_MPI
                  call MPI_ABORT(MPI_COMM_WORLD, myid, mpierror)
#else
                  stop
#endif
               end if                                                   
            else
               iflag = 2
               call avggp(jdim,kdim,idim,
     .                    i1,i2,i3,j1,j2,j3,k1,k2,k3,
     .                    w(lq),w(lqi0),w(lqj0),w(lqk0),w(lx),
     .                    w(ly),w(lz),wk(ixwk),wk(ibwk),
     .                    w(lblk),wk(ixgk),iflag,w(lvis),iovrlp(nbl),
     .                    nbl,nmap,w(lbcj),w(lbck),w(lbci),
     .                    w(lvj0),w(lvk0),w(lvi0),ifunc,n,jdw,kdw,idw,
     .                    nplots,jdimg,kdimg,idimg,nblcg,jsg,ksg,isg,
     .                    jeg,keg,ieg,ninter,iindex,intmax,nsub1,
     .                    maxxe,nblk,nbli,limblk,isva,nblon,mxbli,
     .                    thetay,maxbl,maxgr,myid,myhost,mycomm,
     .                    mblk2nd,inpl3d,nblock,nblkpt,wk(ixvk),
     .                    w(lsj),w(lsk),w(lsi),w(lvol),nummem,
     .                    nset,w(lxib),w(ltj0),w(ltk0),w(lti0),
     .                    w(lvdsp),nvdsp,w(lvdj0),w(lvdk0),w(lvdi0),
     .                    w(lqavg),w(lq2avg),w(lqsavg),w(lqs2avg),
     .                    w(lvdavg),w(lvd2avg),w(lvsj0),w(lvsjdim),
     .                    w(lvsk0),w(lvskdim),w(lvsi0),w(lvsidim))
            end if
         end if
888   continue
      !if(movabs.eq.0) then
      !  !don't continue to output plot3d_avg
      !  return
      !else if(nt.ne.nt/movabs*movabs) then
      !  !don't continue to output plot3d_avg
      !  return                                                          
      !end if
      else
c---- End: modification for averaging at grid points -------------------------
c
      if (nplot3d.le.0) go to 231
c
      ncount    = 0
      np3d      = nplot3d
      ifunc     = 0
      ifuncuse  = 0
c
c     if zone has function file output, all must, and all
c     must have the same function output
c
      if (abs(inpl3d(1,2)).gt.2) then
        ifunc = inpl3d(1,2)
        ifuncuse = 1
      end if
      if (abs(inpl3d(1,2)).eq.2) then
        ifuncuse = ifunct
      end if
c
      do 60 n=1,nplot3d
      if (n.eq.1) then
         rewind(96)
         rewind(97)
         if (myid .eq. myhost) then
            if (ibin.eq.0) then
               if (icallavg.eq.0) write(96,'(i5)') np3d
               write(97,'(i5)') np3d
            else
               if (icallavg.eq.0) write(96) np3d
               write(97) np3d
            end if
         end if
      end if
c
      nbl = inpl3d(n,1)
c
      if (nbl.gt.nblock) then
         if (myid .eq. myhost) then
            write(11,777)nbl
  777       format(6h Block,i3,18h does not exist.  ,
     .             29hNo plot3d_avg output printed.)
         end if
         go to 60
      end if
c
      ncount = ncount+1
      i1 = inpl3d(n,3)
      i2 = inpl3d(n,4)
      i3 = inpl3d(n,5)
      j1 = inpl3d(n,6)
      j2 = inpl3d(n,7)
      j3 = inpl3d(n,8)
      k1 = inpl3d(n,9)
      k2 = inpl3d(n,10)
      k3 = inpl3d(n,11)
      if (inpl3d(n,2).gt.0) then
c        cell center dimensions
         call lead(nbl,lw,lw2,maxbl)
         i2 = min(idim-1,i2)
         j2 = min(jdim-1,j2)
         k2 = min(kdim-1,k2)
         i1 = min(idim-1,i1)
         j1 = min(jdim-1,j1)
         k1 = min(kdim-1,k1)
      end if
      ip3ddim(1,ncount) = (i2-i1)/i3+1
      ip3ddim(2,ncount) = (j2-j1)/j3+1
      ip3ddim(3,ncount) = (k2-k1)/k3+1
   60 continue
c
      if (myid .eq. myhost) then
         if (ibin.eq.0) then
            if (i2d.eq.0) then
               if (icallavg.eq.0) 
     .         write(96,'(3i5)') ((ip3ddim(i,n),i=1,3),n=1,ncount)
               if (ifuncuse.eq.0) then
                  write(97,'(3i5)') ((ip3ddim(i,n),i=1,3),n=1,ncount)
               else
                  write(97,'(4i5)') ((ip3ddim(i,n),i=1,3),2*ifuncuse+3,
     .              n=1,ncount)
               end if
            else
               if (icallavg.eq.0) 
     .         write(96,'(3i5)') ((ip3ddim(i,n),i=2,3),n=1,ncount)
               if (ifuncuse.eq.0) then
                  write(97,'(3i5)') ((ip3ddim(i,n),i=2,3),n=1,ncount)
               else
                  write(97,'(3i5)') ((ip3ddim(i,n),i=2,3),2*ifuncuse+3,
     .              n=1,ncount)
               end if
            end if
         else
            if (i2d.eq.0) then
               if (icallavg.eq.0) 
     .         write(96) ((ip3ddim(i,n),i=1,3),n=1,ncount)
               if (ifuncuse.eq.0) then
                  write(97) ((ip3ddim(i,n),i=1,3),n=1,ncount)
               else
                  write(97) ((ip3ddim(i,n),i=1,3),2*ifuncuse+3,
     .              n=1,ncount)
               end if
            else
               if (icallavg.eq.0) 
     .         write(96) ((ip3ddim(i,n),i=2,3),n=1,ncount)
               if (ifuncuse.eq.0) then
                  write(97) ((ip3ddim(i,n),i=2,3),n=1,ncount)
               else
                  write(97) ((ip3ddim(i,n),i=2,3),2*ifuncuse+3,
     .              n=1,ncount)
               end if
            end if
         end if
      end if
c
c     correspondence between global block number and plot3d block
c     number stored in nmap(n) for n=1,nblock
c
      do 1097 n = 1,nblock
      nmap(n) = 1
      do 1098 nnn = 1,nplot3d
      m = inpl3d(nnn,1)
      if (n.eq.m) nmap(n) = nnn
 1098 continue
 1097 continue             
c
      if (myid.eq.myhost) then
         if (lhdr .gt. 0) write(11,1096)
      end if
 1096 format(1h )
c
      do 70 n=1,nplot3d
c
      nbl = inpl3d(n,1)
c
      if (nbl.gt.nblock .or. nbl.le. 0) go to 70
c
      if (iblnkfr .eq. 0) then
c
c        temporarily set blank values at fringe points (not holes)
c        to 1 for plotting purposes (helps reduce gaps in plots)
c
         call lead(nbl,lw,lw2,maxbl)
         if (mblk2nd(nbl).eq.myid .and. iovrlp(nbl).ne.0) then
            call blnkfr(nbl,iibg,kkbg,jjbg,ibpntsg,lbg,iitot,w(lblk),
     .                  jdim,kdim,idim,maxbl,1.)
         end if
      end if
c
      i1 = inpl3d(n,3)
      i2 = inpl3d(n,4)
      i3 = inpl3d(n,5)
      j1 = inpl3d(n,6)
      j2 = inpl3d(n,7)
      j3 = inpl3d(n,8)
      k1 = inpl3d(n,9)
      k2 = inpl3d(n,10)
      k3 = inpl3d(n,11)
c
      iflag = 1
c
      if (-2.le.0) then
c
c        only grid point type is supported for output of averaged data 
c
         if (mblk2nd(nbl).eq.myid .or. myid.eq.myhost) then
c
            call lead(nbl,lw,lw2,maxbl)
c
            jdw = (j2-j1)/j3 + 1
            kdw = (k2-k1)/k3 + 1
            idw = (i2-i1)/i3 + 1
c
            ixwk = 1
            ifuncdim = max(5,ifunct)
            ibwk = ixwk + jdw*kdw*idw*(2*ifuncdim+3)
            ixgk = ibwk + jdim*kdim*idim*2
            ixvk = ixgk + jdw*kdw*idw*4
            nroom = nwork - (ixvk+jdw*kdw*idw*(2*ifuncdim+3)-1)
            if (nroom .lt. 0.) then
               if (myid.eq.myhost) then
                  write(11,'('' not enough memory for plot3d_avg'')')
                  write(11,'('' have, need = '',2i12)') nwork,
     .            nwork-nroom
                  write(11,'('' not writing out plot3d files'')')
               end if
            else
               call plot3d_avg(jdim,kdim,idim,i1,i2,i3,j1,j2,j3,k1,k2,
     .                     k3,w(lq),w(lqi0),w(lqj0),w(lqk0),w(lx),
     .                     w(ly),w(lz),wk(ixwk),wk(ibwk),
     .                     w(lblk),wk(ixgk),iflag,w(lvis),iovrlp(nbl),
     .                     nbl,nmap,w(lbcj),w(lbck),w(lbci),
     .                     w(lvj0),w(lvk0),w(lvi0),ifunc,n,jdw,kdw,idw,
     .                     nplots,jdimg,kdimg,idimg,nblcg,jsg,ksg,isg,
     .                     jeg,keg,ieg,ninter,iindex,intmax,nsub1,
     .                     maxxe,nblk,nbli,limblk,isva,nblon,mxbli,
     .                     thetay,maxbl,maxgr,myid,myhost,mycomm,
     .                     mblk2nd,inpl3d,nblock,nblkpt,wk(ixvk),
     .                     w(lsj),w(lsk),w(lsi),w(lvol),nummem,ifuncdim,
     .                     w(lqavg),w(lq2avg),w(lqsavg),w(lqs2avg),
     .                     w(lvdavg),w(lvd2avg),nvdsp,
     .                     w(lvsj0),w(lvsjdim),w(lvsk0),w(lvskdim),
     .                     w(lvsi0),w(lvsidim))
            end if
c
         end if
c
      end if
c
      if (iblnkfr .eq. 0) then
c
c        reset blank values at fringe points to 0.
c
         if (mblk2nd(nbl).eq.myid .and. iovrlp(nbl).ne.0) then
            call blnkfr(nbl,iibg,kkbg,jjbg,ibpntsg,lbg,iitot,w(lblk),
     .                  jdim,kdim,idim,maxbl,0.)
         end if
      end if
c
   70 continue
c
      if (myid.eq.myhost) then
         if (lhdr .gt. 0) write(11,1096)
      endif
c
c     never output average solution grid
c     it is the same as the transient solution grid
c
      if (iunst.eq.0) then
         icallavg = 1
      else
         icallavg = 1
      end if
c
  231 continue
c
c***********************************************************************
c     Print solution data.
c***********************************************************************
c
      if (nprint.gt.0) then
c
      if (myid.eq.myhost) then
         if (lhdr .gt. 0 .and. nplot3d .le. 0) write(11,1096)
      end if
c
c     dimensions of surface
c
      allocate(iprdim(3,nprint))
      ncount = 0
      do 90 n=1,nprint 
c
        nbl = inpr(n,1)
c
        if (nbl.gt.nblock) then
           if (myid .eq. myhost) then
              write(11,77) nbl
           end if
           go to 90
        end if
c
        ncount = ncount+1
        i1 = inpr(n,3)
        i2 = inpr(n,4)
        i3 = inpr(n,5)
        j1 = inpr(n,6)
        j2 = inpr(n,7)
        j3 = inpr(n,8)
        k1 = inpr(n,9)
        k2 = inpr(n,10)
        k3 = inpr(n,11)
c
        if (inpr(n,2).gt.0) then
c          cell center dimensions
           call lead(nbl,lw,lw2,maxbl)
           i2 = min(idim-1,i2)
           j2 = min(jdim-1,j2)
           k2 = min(kdim-1,k2)
           i1 = min(idim-1,i1)
           j1 = min(jdim-1,j1)
           k1 = min(kdim-1,k1)
        end if
        iprdim(1,ncount) = (i2-i1)/i3+1
        iprdim(2,ncount) = (j2-j1)/j3+1
        iprdim(3,ncount) = (k2-k1)/k3+1
c
   90 continue
c
      if (myid .eq. myhost) then 
c
         rewind(176)
         rewind(177)
         if (ibin.eq.0) then
             if (icallavg.eq.0) write(176,'(i5)') ncount
             write(177,'(i5)') ncount
         else
             if (icallavg.eq.0) write(176) ncount
             write(177) ncount
         end if
c
         if (ibin.eq.0) then
            if (i2d.eq.0) then
               if (icallavg.eq.0) 
     .         write(176,'(3i5)') ((iprdim(i,n),i=1,3),n=1,ncount)
               write(177,'(4i5)') ((iprdim(i,n),i=1,3),28,n=1,ncount)
            else
               if (icallavg.eq.0) 
     .         write(176,'(2i5)') ((iprdim(i,n),i=2,3),n=1,ncount)
               write(177,'(3i5)') ((iprdim(i,n),i=2,3),28,n=1,ncount)
            end if
         else
            if (i2d.eq.0) then
               if (icallavg.eq.0)
     .         write(176) ((iprdim(i,n),i=1,3),n=1,ncount)
               write(177) ((iprdim(i,n),i=1,3),28,n=1,ncount)
            else
               if (icallavg.eq.0) 
     .         write(176) ((iprdim(i,n),i=2,3),n=1,ncount)
               write(177) ((iprdim(i,n),i=2,3),28,n=1,ncount)
            end if
         end if
      end if
c
      do 80 n=1,nprint
c
      nbl = inpr(n,1)
c
      if (nbl.gt.nblock) then
         if (myid .eq. myhost) then
            write(11,77)nbl
         end if
   77    format(6h Block,i3,36h does not exist.  No output printed.)
         go to 80
      end if
c
      i1 = inpr(n,3)
      i2 = inpr(n,4)
      i3 = inpr(n,5)
      j1 = inpr(n,6)
      j2 = inpr(n,7)
      j3 = inpr(n,8)
      k1 = inpr(n,9)
      k2 = inpr(n,10)
      k3 = inpr(n,11)
c  
      iflag = 2
c
      if (inpr(n,2).eq.0) then
c
c        grid point data
c
         if (mblk2nd(nbl).eq.myid .or. myid.eq.myhost) then
c
            call lead(nbl,lw,lw2,maxbl)
c
            jdw = (j2-j1)/j3 + 1
            kdw = (k2-k1)/k3 + 1
            idw = (i2-i1)/i3 + 1
c
c           check storage availability
c           set as 2*nset+3 for consistency with 2*ifuncdim+3 of average flowfield
c           it is enough to set as 2*nset
c
            ixwk = 1
            nset = 14
            ibwk = ixwk + jdw*kdw*idw*(2*nset+3)
            ixgk = ibwk + jdim*kdim*idim*2
            ixvk = ixgk + jdw*kdw*idw*4
            nroom = nwork - (ixvk+jdw*kdw*idw*(2*nset+3)-1)
            if (nroom .lt. 0.) then
               if (myid.eq.myhost) then
                  write(11,'('' not enough memory for plot3d_avg'')')
                  write(11,'('' have, need = '',2i12)') nwork,
     .            nwork-nroom
                  write(11,'('' not writing out plot3d file'')')
               end if
            else
               call plot3d_avg(jdim,kdim,idim,i1,i2,i3,j1,j2,j3,k1,k2,
     .                     k3,w(lq),w(lqi0),w(lqj0),w(lqk0),w(lx),
     .                     w(ly),w(lz),wk(ixwk),wk(ibwk),
     .                     w(lblk),wk(ixgk),iflag,w(lvis),iovrlp(nbl),
     .                     nbl,nmap,w(lbcj),w(lbck),w(lbci),
     .                     w(lvj0),w(lvk0),w(lvi0),ifunc,n,jdw,kdw,idw,
     .                     nplots,jdimg,kdimg,idimg,nblcg,jsg,ksg,isg,
     .                     jeg,keg,ieg,ninter,iindex,intmax,nsub1,
     .                     maxxe,nblk,nbli,limblk,isva,nblon,mxbli,
     .                     thetay,maxbl,maxgr,myid,myhost,mycomm,
     .                     mblk2nd,inpl3d,nblock,nblkpt,wk(ixvk),
     .                     w(lsj),w(lsk),w(lsi),w(lvol),nummem,nset,
     .                     w(lqavg),w(lq2avg),w(lqsavg),w(lqs2avg),
     .                     w(lvdavg),w(lvd2avg),nvdsp,
     .                     w(lvsj0),w(lvsjdim),w(lvsk0),w(lvskdim),
     .                     w(lvsi0),w(lvsidim))
            end if
         end if
      end if
c
   80 continue
c
      if (myid.eq.myhost) then
         if (lhdr .gt. 0) write(11,1096)
      end if
c
c     never output average solution grid
c     it is the same as the transient solution grid
c
      if (iunst.eq.0) then
         icallavg = 1
      else
         icallavg = 1
      end if
c
      end if
      end if
      return
      end
