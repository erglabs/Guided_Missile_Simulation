
#include "GMS_config.fpp"

!/*MIT License
!Copyright (c) 2020 Bernard Gingold
!Permission is hereby granted, free of charge, to any person obtaining a copy
!of this software and associated documentation files (the "Software"), to deal
!in the Software without restriction, including without limitation the rights
!to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
!copies of the Software, and to permit persons to whom the Software is
!furnished to do so, subject to the following conditions:
!The above copyright notice and this permission notice shall be included in all
!copies or substantial portions of the Software.
!THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
!IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
!FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
!AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
!LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
!OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
!SOFTWARE.
!*/

module rcs_planar_zmm16r4



!===================================================================================85
 !---------------------------- DESCRIPTION ------------------------------------------85
 !
 !
 !
 !          Module  name:
 !                         rcs_planar_zmm16r4
 !          
 !          Purpose:
 !                        Various characteristics of analytically derived Radar
 !                        Cross Section of planar objects  
 !                        Based  on George T. Ruck, Donald E. Barrick , William D. Stuart , 
 !                        - "Radar Cross Section Handbook 1 and 2" (1970, Kluwer Academic Plenum Publishers) 
 !                        This module contains only explicitly vectorized (SIMD)
 !                        
 !          History:
 !                        Date: 01-09-2024
 !                        Time: 07:07 GMT+2
 !                        
 !          Version:
 !
 !                      Major: 1
 !                      Minor: 0
 !                      Micro: 0
 !
 !          Author:  
 !                      Bernard Gingold
 !          
 !                 
 !          References:
 !         
 !                      George T. Ruck, Donald E. Barrick , William D. Stuart
 !                      Radar Cross Section Handbook 1 and 2" (1970, Kluwer Academic Plenum Publishers)     
 !         
 !          E-mail:
 !                  
 !                      beniekg@gmail.com
!==================================================================================85
    ! Tab:5 col - Type and etc.. definitions
    ! Tab:10,11 col - Type , function and subroutine code blocks.

    use mod_kinds,    only : i4,sp
    use mod_vectypes, only : ZMM16r4_t
    use avx512_cvec16_v2

    public
    implicit none
    
     ! Major version
     integer(kind=i4),  parameter :: RCS_PLANAR_ZMM16R4_MAJOR = 1
     ! Minor version
     integer(kind=i4),  parameter :: RCS_PLANAR_ZMM16R4_MINOR = 0
     ! Micro version
     integer(kind=i4),  parameter :: RCS_PLANAR_ZMM16R4_MICRO = 0
     ! Full version
     integer(kind=i4),  parameter :: RCS_PLANAR_ZMM16R4_FULLVER =   &
            1000*RCS_PLANAR_ZMM16R4_MAJOR+100*RCS_PLANAR_ZMM16R4_MINOR+10*RCS_PLANAR_ZMM16R4_MICRO
     ! Module creation date
     character(*),        parameter :: RCS_PLANAR_ZMM16R4_CREATE_DATE = "01-09-2024 07:10 +00200 (SUN 01 SEP 2024 GMT+2)"
     ! Module build date
     character(*),        parameter :: RCS_PLANAR_ZMM16R4_BUILD_DATE  = __DATE__ " " __TIME__
     ! Module author info
     character(*),        parameter :: RCS_PLANAR_ZMM16R4_AUTHOR      = "Programmer: Bernard Gingold, contact: beniekg@gmail.com"
     ! Short description
     character(*),        parameter :: RCS_PLANAR_ZMM16R4_SYNOPSIS    = "Analytical Cylindrical objects RCS characteristics and models explicitly vectorized (SIMD)."
    
#ifndef __RCS_PLANAR_PF_CACHE_HINT__
#define __RCS_PLANAR_PF_CACHE_HINT__ 1
#endif 
    
    
    contains

        !/*
        !               Complex impedances.
        !               Formula 7.1-6
        !           */


      pure function zi_f716_v512b_ps(tht,mu,eps) result(z)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: zi_f716_v512b_ps
            !dir$ attributes forceinline :: zi_f716_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: zi_f716_v512b_ps
            use mod_vecconsts, only : v16_0,v16_1
            type(ZMM16r4_t),   intent(in) :: tht
            type(ZMM16c4),     intent(in) :: mu
            type(ZMM16c4),     intent(in) :: eps
            type(ZMM16c4) :: z
            ! Locals
            type(ZMM16r4_t), automatic :: cost
            type(ZMM16r4_t), automatic :: invc
            type(ZMM16r4_t), automatic :: wrkc
            type(ZMM16c4),   automatic :: div
            type(ZMM16c4),   automatic :: csq
            !dir$ attributes align : 64 :: cost
            !dir$ attributes align : 64 :: invc
            !dir$ attributes align : 64 :: wrkc
            !dir$ attributes align : 64 :: div
            !dir$ attributes align : 64 :: csq
            cost.v = cos(tht.v)
            wrkc.v = v16_0.v
            div    = mu/eps       
            invc.v = v16_1.v/cost.v
            csq    = csqrt_c16(div)
            z.re   = invc.v*csq.re
            z.im   = invc.v*csq.im
      end function zi_f716_v512b_ps
      
      
       !/*
       !                   Equivalent complex impedances.
       !                   Formula 7.1-4
       !             */
      
      pure function R_f714_v512b_ps(tht1,mu1,eps1,tht2,mu2,eps2) result(R)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: R_f714_v512b_ps
            !dir$ attributes forceinline :: R_f714_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: R_f714_v512b_ps
            type(ZMM16r4_t),    intent(in) :: tht1
            type(ZMM16c4),      intent(in) :: mu1
            type(ZMM16c4),      intent(in) :: eps1
            type(ZMM16r4_t),    intent(in) :: tht2
            type(ZMM16c4),      intent(in) :: mu2
            type(ZMM16c4),      intent(in) :: eps2
            type(ZMM16c4)  :: R
            ! Locals
            type(ZMM16c4), automatic :: z1
            type(ZMM16c4), automatic :: z2
            type(ZMM16c4), automatic :: t0
            type(ZMM16c4), automatic :: t1 
            !dir$ attributes align : 64 :: z1
            !dir$ attributes align : 64 :: z2
            !dir$ attributes align : 64 :: t0
            !dir$ attributes align : 64 :: t1
            z1    = zi_f716_v512b_ps(tht1,mu1,eps1)
            z2    = zi_f716_v512b_ps(tht2,mu2,eps2)
            t0    = z1-z2
            t1    = z1+z2
            t0.re = -t0.re
            t0.im = -t0.im
            R     = t0/t1 
      end function R_f714_v512b_ps
      
      
      !            /*
      !                  Transmission coefficient components.
      !                  Formula 7.1-5
      !              */
      
       pure function T_f715_v512b_ps(tht1,mu1,eps1,tht2,mu2,eps2) result(T)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: T_f715_v512b_ps
            !dir$ attributes forceinline :: T_f715_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: T_f715_v512b_ps
            type(ZMM16r4_t),      intent(in) :: tht1
            type(ZMM16c4),        intent(in) :: mu1
            type(ZMM16c4),        intent(in) :: eps1
            type(ZMM16r4_t),      intent(in) :: tht2
            type(ZMM16c4),        intent(in) :: mu2
            type(ZMM16c4),        intent(in) :: eps2
            type(ZMM16c4) :: T
            ! Locals
            type(ZMM16r4_t), parameter :: C20 = ZMM16r4_t(2.0_sp)
            type(ZMM16c4), automatic   :: z1
            type(ZMM16c4), automatic   :: z2
            type(ZMM16c4), automatic   :: t0
            type(ZMM16c4), automatic   :: t1
             !dir$ attributes align : 64 :: C20
             !dir$ attributes align : 64 :: z1
             !dir$ attributes align : 64 :: z2
             !dir$ attributes align : 64 :: t0
             !dir$ attributes align : 64 :: t1
            z2 = zi_f716_v512b_ps(tht2,mu2,eps2)
            z1 = zi_f716_v512b_ps(tht1,mu1,eps1)
            t0 = z2*C20
            t1 = z1+z2
            R  = t0/t1
       end function T_f715_v512b_ps
       
       ! /*
       !                 Reflection coefficient special cases:
       !                 1) k1<k2, eps1,eps2 (real), mu1 = m2 = mu0
       !                 Formula 7.1-17
       !            */
       
       pure function R_f7117_v512b_ps(tht,eps1,eps2) result(R)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: R_f7117_v512b_ps
            !dir$ attributes forceinline :: R_f7117_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: R_f7117_v512b_ps
            type(ZMM16r4_t),          intent(in) :: tht
            type(ZMM16r4_t),          intent(in) :: eps1
            type(ZMM16r4_t),          intent(in) :: eps2
            type(ZMM16r4_t)  :: R
            ! Locals
            type(ZMM16r4_t), automatic :: e1e2
            type(ZMM16r4_t), automatic :: sqr1
            type(ZMM16r4_t), automatic :: sqr2
            type(ZMM16r4_t), automatic :: num
            type(ZMM16r4_t), automatic :: den
            type(ZMM16r4_t), automatic :: cost
            type(ZMM16r4_t), automatic :: sint
            type(ZMM16r4_t), automatic :: x0
            type(ZMM16r4_t), automatic :: x1
            !dir$ attributes align : 64 :: e1e2
            !dir$ attributes align : 64 :: sqr1
            !dir$ attributes align : 64 :: sqr2
            !dir$ attributes align : 64 :: num
            !dir$ attributes align : 64 :: den
            !dir$ attributes align : 64 :: cost
            !dir$ attributes align : 64 :: sint
            !dir$ attributes align : 64 :: x0
            !dir$ attributes align : 64 :: x1
            type(ZMM16r4_t), parameter :: C1 = ZMM16r4_t(1.0_sp)
#if (GMS_EXPLICIT_VECTORIZE) == 1
             integer(kind=i4) :: j
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0,15
                e1e2.v(j) = eps1.v(j)/eps2.v(j)
                cost.v(j) = cos(tht.v(j))
                sqr1.v(j) = sqrt(e1e2.v(j))
                sint.v(j) = sin(tht.v(j))
                x0.v(j)   = sqr1.v(j)*cost.v(j)
                x1.v(j)   = C1.v(j)-e1e2.v(j)*(sint.v(j)*sint.v(j))
                sqr2.v(j) = sqrt(x1.v(j))
                num.v(j)  = x0.v(j)-x1.v(j)
                den.v(j)  = x0.v(j)+x1.v(j)
                R.v(j)    = num.v(j)/den.v(j)      
             end do
#else
                e1e2.v = eps1.v/eps2.v
                cost.v = cos(tht.v)
                sqr1.v = sqrt(e1e2.v)
                sint.v = sin(tht.v)
                x0.v   = sqr1.v*cost.v
                x1.v   = C1.v-e1e2.v*(sint.v*sint.v)
                sqr2.v = sqrt(x1.v)
                num.v  = x0.v-x1.v
                den.v  = x0.v+x1.v
                R.v    = num.v/den.v      
#endif
       end function R_f7117_v512b_ps
       
       
       !  /*
       !                 Reflection coefficient special cases:
       !                 1) k1<k2, eps1,eps2 (real), mu1 = m2 = mu0
       !                 Formula 7.1-18
       !            */
       
       pure function R_f7118_v512b_ps(tht,eps1,eps2) result(R)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: R_f7118_v512b_ps
            !dir$ attributes forceinline :: R_f7118_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: R_f7118_v512b_ps
            type(ZMM16r4_t),          intent(in) :: tht
            type(ZMM16r4_t),          intent(in) :: eps1
            type(ZMM16r4_t),          intent(in) :: eps2
            type(ZMM16r4_t)  :: R
            ! Locals
            type(ZMM16r4_t), automatic :: e1e2
            type(ZMM16r4_t), automatic :: sqr1
            type(ZMM16r4_t), automatic :: sqr2
            type(ZMM16r4_t), automatic :: num
            type(ZMM16r4_t), automatic :: den
            type(ZMM16r4_t), automatic :: cost
            type(ZMM16r4_t), automatic :: sint
            type(ZMM16r4_t), automatic :: x0
            type(ZMM16r4_t), automatic :: x1
            !dir$ attributes align : 64 :: e1e2
            !dir$ attributes align : 64 :: sqr1
            !dir$ attributes align : 64 :: sqr2
            !dir$ attributes align : 64 :: num
            !dir$ attributes align : 64 :: den
            !dir$ attributes align : 64 :: cost
            !dir$ attributes align : 64 :: sint
            !dir$ attributes align : 64 :: x0
            !dir$ attributes align : 64 :: x1
            type(ZMM16r4_t), parameter :: C1 = ZMM16r4_t(1.0_sp)
#if (GMS_EXPLICIT_VECTORIZE) == 1
             integer(kind=i4) :: j
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0,15
                e1e2.v(j) = eps2.v(j)/eps1.v(j)
                cost.v(j) = cos(tht.v(j))
                sqr1.v(j) = sqrt(e1e2.v(j))
                sint.v(j) = sin(tht.v(j))
                x0.v(j)   = sqr1.v(j)*cost.v(j)
                x1.v(j)   = C1.v(j)-e1e2.v(j)*(sint.v(j)*sint.v(j))
                sqr2.v(j) = sqrt(x1.v(j))
                num.v(j)  = x0.v(j)-x1.v(j)
                den.v(j)  = x0.v(j)+x1.v(j)
                R.v(j)    = num.v(j)/den.v(j)
             end do
#else
                e1e2.v = eps2.v/eps1.v
                cost.v = cos(tht.v)
                sqr1.v = sqrt(e1e2.v)
                sint.v = sin(tht.v)
                x0.v   = sqr1.v*cost.v
                x1.v   = C1.v-e1e2.v*(sint.v*sint.v)
                sqr2.v = sqrt(x1.v)
                num.v  = x0.v-x1.v
                den.v  = x0.v+x1.v
                R.v   = num.v/den.v
#endif            
       end function R_f7118_v512b_ps
       
        !  /*
        !                Reflection coefficient special cases:
        !                2) k2<k1, eps1,eps2 (real), mu1 = mu2 = mu0
        !                Formula 7.1-23
        !           */
        
        pure function R_f7123_v512b_ps(tht,eps1,eps2) result(R)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: R_f7123_v512b_ps
            !dir$ attributes forceinline :: R_f7123_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: R_f7123_v512b_ps
            use mod_vecconsts, only : v16_0
            type(ZMM16r4_t),          intent(in) :: tht
            type(ZMM16r4_t),          intent(in) :: eps1
            type(ZMM16r4_t),          intent(in) :: eps2
            type(ZMM16c4)  :: R
            ! Locals
            type(ZMM16r4_t), parameter :: CN20 = ZMM16r4_t(-2.0f)
            type(ZMM16c4),   automatic :: ea
            type(ZMM16r4_t), automatic :: sint
            type(ZMM16r4_t), automatic :: cost
            type(ZMM16r4_t), automatic :: e2e1
            type(ZMM16r4_t), automatic :: rat
            type(ZMM16r4_t), automatic :: arg
            type(ZMM16r4_t), automatic :: atarg
            type(ZMM16r4_t), automatic :: x0
            type(ZMM16r4_t), automatic :: x1
            !dir$ attributes align : 64 :: CN20
            !dir$ attributes align : 64 :: ea
            !dir$ attributes align : 64 :: sint
            !dir$ attributes align : 64 :: cost
            !dir$ attributes align : 64 :: e2e1
            !dir$ attributes align : 64 :: rat
            !dir$ attributes align : 64 :: arg
            !dir$ attributes align : 64 :: atarg
            !dir$ attributes align : 64 :: x0
            !dir$ attributes align : 64 :: x1
#if (GMS_EXPLICIT_VECTORIZE) == 1
             type(ZMM16r4_t), automatic :: t0
             !dir$ attributes align : 64 :: t0
             integer(kind=i4) :: j
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0,15
                 e2e1.v(j) = eps2.v(j)/eps1.v(j)
                 cost.v(j) = cos(tht.v(j))
                 ea.re(j)  = v16_0.v(j)
                 sint.v(j) = sin(tht.v(j))
                 x0.v(j)   = cost.v(j)*cost.v(j)
                 x1.v(j)   = (sint.v(j)*sint.v(j))-e2e1.v(j)
                 rat.v(j)  = x1.v(j)/x0.v(j)
                 arg.v(j)  = sqrt(rat.v(j))
                 atarg.v(j)= atan(arg.v(j))
                 ea.im(j)  = CN20.v(j)*atarg.v(j)
                 t0.v(j)   = exp(ea.re(j))
                 R.re(j)   = t0.v(j)*cos(ea.re(j))
                 R.im(j)   = t0.v(j)*sin(ea.im(j))
             end do
#else            
            e2e1.v = eps2.v/eps1.v
            cost.v = cos(tht.v)
            ea.re  = v16_0.v
            sint.v = sin(tht.v)
            x0.v   = cost.v*cost.v
            x1.v   = sint.v*sint.v-e2e1.v
            rat.v  = x1.v/x0.v
            arg.v  = sqrt(rat.v)
            atarg.v= atan(arg.v)
            ea.im  = CN20.v*atarg.v
            R      = cexp_c16(ea)
#endif
        end function R_f7123_v512b_ps
        
        
        !            /*
        !                Reflection coefficient special cases:
        !                2) k2<k1, eps1,eps2 (real), mu1 = mu2 = mu0
        !                Formula 7.1-24
        !           */
        
         pure function R_f7124_v512b_ps(tht,eps1,eps2) result(R)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: R_f7124_v512b_ps
            !dir$ attributes forceinline :: R_f7124_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: R_f7124_v512b_ps
            use mod_vecconsts, only : v16_0, v16_1
            type(ZMM16r4_t),          intent(in) :: tht
            type(ZMM16r4_t),          intent(in) :: eps1
            type(ZMM16r4_t),          intent(in) :: eps2
            type(ZMM16c4)  :: R
            !Locals
            type(ZMM16r4_t), parameter :: CN20 = ZMM16r4_t(-2.0_sp)
            type(ZMM16c4),   automatic :: ea
            type(ZMM16r4_t), automatic :: sint
            type(ZMM16r4_t), automatic :: cost
            type(ZMM16r4_t), automatic :: e2e1
            type(ZMM16r4_t), automatic :: e1e2
            type(ZMM16r4_t), automatic :: rat
            type(ZMM16r4_t), automatic :: arg
            type(ZMM16r4_t), automatic :: atarg
            type(ZMM16r4_t), automatic :: x0
            type(ZMM16r4_t), automatic :: x1
            !dir$ attributes align : 64 :: CN20
            !dir$ attributes align : 64 :: ea
            !dir$ attributes align : 64 :: sint
            !dir$ attributes align : 64 :: cost
            !dir$ attributes align : 64 :: e2e1
            !dir$ attributes align : 64 :: rat
            !dir$ attributes align : 64 :: arg
            !dir$ attributes align : 64 :: atarg
            !dir$ attributes align : 64 :: x0
            !dir$ attributes align : 64 :: x1
#if (GMS_EXPLICIT_VECTORIZE) == 1
             type(ZMM16r4_t), automatic :: t0
             !dir$ attributes align : 64 :: t0
             integer(kind=i4) :: j
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15
                e2e1.v(j) = eps2.v(j)/eps1.v(j)
                sint.v(j) = sin(tht.v(j))
                ea.re(j)  = v16_0.v(j)
                cost.v(j) = cos(tht.v(j))
                x0.v(j)   = e2e1.v(j)*(sint.v(j)*sint.v(j))-v16_1.v(j)
                e1e2.v(j) = eps1.v(j)/eps2.v(j)
                x1.v(j)   = e1e2.v(j)*(cost.v(j)*cost.v(j))
                rat.v(j)  = x0.v(j)/x1.v(j)
                arg.v(j)  = sqrt(rat.v(j))
                atarg.v(j)= atan(arg.v(j))
                ea.im(j)  = CN20.v(j)*atarg.v(j)
                t0.v(j)   = exp(ea.re(j))
                R.re(j)   = t0.v(j)*cos(ea.re(j))
                R.im(j)   = t0.v(j)*sin(ea.im(j))
             end do
#else
                e2e1.v = eps2.v/eps1.v
                sint.v = sin(tht.v)
                ea.re  = v16_0.v
                cost.v = cos(tht.v)
                x0.v   = e2e1.v*(sint.v*sint.v)-v16_1.v
                e1e2.v = eps1.v/eps2.v
                x1.v   = e1e2.v*(cost.v*cost.v)
                rat.v  = x0.v/x1.v
                arg.v  = sqrt(rat.v)
                atarg.v= atan(arg.v)
                ea.im  = CN20.v*atarg.v
                R      = cexp_c16(ea)
#endif            
         end function R_f7124_v512b_ps
         
        !  /*
        !               Lateral displacement of the incident ray.
        !               Formula 7.1-27
        !           */
        
        pure function D_f7127_v512b_ps(gam0,tht,eps2,eps1) result(D)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: D_f7127_v512b_ps
            !dir$ attributes forceinline :: D_f7127_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: D_f7127_v512b_ps
            type(ZMM16r4_t),          intent(in) :: gam0
            type(ZMM16r4_t),          intent(in) :: tht
            type(ZMM16r4_t),          intent(in) :: eps1
            type(ZMM16r4_t),          intent(in) :: eps2
            type(ZMM16r4_t)  :: D
            ! Locals
            type(ZMM16r4_t),  parameter :: C0318309886183790671537767526745 =  &
                                                         ZMM16r4_t(0.318309886183790671537767526745_sp)
            type(ZMM16r4_t), automatic :: g0pi
            type(ZMM16r4_t), automatic :: ttht
            type(ZMM16r4_t), automatic :: sint
            type(ZMM16r4_t), automatic :: e2e1
            type(ZMM16r4_t), automatic :: sqr
            type(ZMM16r4_t), automatic :: rat
            !dir$ attributes align : 64 :: C0318309886183790671537767526745
            !dir$ attributes align : 64 :: g0pi
            !dir$ attributes align : 64 :: ttht
            !dir$ attributes align : 64 :: sint
            !dir$ attributes align : 64 :: e2e1
            !dir$ attributes align : 64 :: sqr
            !dir$ attributes align : 64 :: rat
#if (GMS_EXPLICIT_VECTORIZE) == 1
             integer(kind=i4) :: j
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15
                g0pi.v(j) = gam0.v(j)*C0318309886183790671537767526745.v(j)
                sint.v(j) = sin(tht.v(j))
                e2e1.v(j) = eps2.v(j)/eps1.v(j)
                ttht.v(j) = tan(tht.v(j))
                sint.v(j) = (sint.v(j)*sint.v(j))-e2e1.v(j)
                sqr.v(j)  = sqrt(sint.v(j))
                rat.v(j)  = ttht.v(j)/sqr.v(j)
                D.v(j)    = g0pi.v(j)*rat.v(j)
             end do
#else
                g0pi.v = gam0.v*C0318309886183790671537767526745.v
                sint.v = sin(tht.v)
                e2e1.v = eps2.v/eps1.v
                ttht.v = tan(tht.v)
                sint.v = (sint.v*sint.v)-e2e1.v
                sqr.v  = sqrt(sint.v)
                rat.v  = ttht.v/sqr.v
                D.v    = g0pi.v*rat.v
#endif
        end function D_f7127_v512b_ps
        
        ! /*
        !               Lateral displacement of the incident ray.
        !               Formula 7.1-28
        !           */
        
        pure function D_f7128_v512b_ps(gam0,tht,eps2,eps1) result(D)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: D_f7128_v512b_ps
            !dir$ attributes forceinline :: D_f7128_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: D_f7128_v512b_ps
            type(ZMM16r4_t),          intent(in) :: gam0
            type(ZMM16r4_t),          intent(in) :: tht
            type(ZMM16r4_t),          intent(in) :: eps1
            type(ZMM16r4_t),          intent(in) :: eps2
            type(ZMM16r4_t)  :: D
            ! Locals
            type(ZMM16r4_t),  parameter :: C0318309886183790671537767526745 =  &
                                                         ZMM16r4_t(0.318309886183790671537767526745_sp)
            type(ZMM16r4_t), automatic :: g0pi
            type(ZMM16r4_t), automatic :: ttht
            type(ZMM16r4_t), automatic :: sint
            type(ZMM16r4_t), automatic :: e2e1
            type(ZMM16r4_t), automatic :: e1e2
            type(ZMM16r4_t), automatic :: sqr
            type(ZMM16r4_t), automatic :: rat
            !dir$ attributes align : 64 :: C0318309886183790671537767526745
            !dir$ attributes align : 64 :: g0pi
            !dir$ attributes align : 64 :: ttht
            !dir$ attributes align : 64 :: sint
            !dir$ attributes align : 64 :: e2e1
            !dir$ attributes align : 64 :: e1e2
            !dir$ attributes align : 64 :: sqr
            !dir$ attributes align : 64 :: rat   
#if (GMS_EXPLICIT_VECTORIZE) == 1
             integer(kind=i4) :: j
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15
                g0pi.v(j) = gam0.v(j)*C0318309886183790671537767526745.v(j)
                sint.v(j) = sin(tht.v(j))
                e2e1.v(j) = eps2.v(j)/eps1.v(j)
                ttht.v(j) = tan(tht.v(j))
                sint.v(j) = (sint.v(j)*sint.v(j))-e2e1.v(j)
                e1e2.v(j) = eps1.v(j)/eps2.v(j)
                sqr.v(j)  = sqrt(sint.v(j))
                rat.v(j)  = ttht.v(j)/sqr.v(j)
                D.v(j)    = g0pi.v(j)*(e1e2.v(j)*rat.v(j))
             end do
#else
                g0pi.v = gam0.v*C0318309886183790671537767526745.v
                sint.v = sin(tht.v)
                e2e1.v = eps2.v/eps1.v
                ttht.v = tan(tht.v)
                sint.v = (sint.v*sint.v)-e2e1.v
                e1e2.v = eps1.v/eps2.v
                sqr.v  = sqrt(sint.v)
                rat.v  = ttht.v/sqr.v
                D.v    = g0pi.v*(e1e2.v*rat.v)
#endif                                         
        end function D_f7128_v512b_ps
        
        ! /*
        !                     For (k1/k2)^2*sin^2(theta)<<1 (Simplification
        !                     of formulae 7.1-9 and 7.1-10).
        !                     Formula 7.1-29
        !                */
        
        pure function R_f7129_v512b_ps(tht,mu1,eps1,mu2,eps2) result(R)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: R_f7129_v512b_ps
            !dir$ attributes forceinline :: R_f7129_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: R_f7129_v512b_ps
            type(ZMM16r4_t),  intent(in) :: tht
            type(ZMM16c4),    intent(in) :: mu1
            type(ZMM16c4),    intent(in) :: eps1
            type(ZMM16c4),    intent(in) :: mu2
            type(ZMM16c4),    intent(in) :: eps2
            type(ZMM16c4) :: R
            ! Locals
            type(ZMM16c4),   automatic :: z1
            type(ZMM16c4),   automatic :: z2
            type(ZMM16c4),   automatic :: num
            type(ZMM16c4),   automatic :: den
            type(ZMM16r4_t), automatic :: cost
#if (GMS_EXPLICIT_VECTORIZE) == 1
            type(ZMM16r4_t), automatic :: zmm0
            type(ZMM16r4_t), automatic :: zmm1
            type(ZMM16r4_t), automatic :: zmm2
            type(ZMM16r4_t), automatic :: zmm3
            type(ZMM16r4_t), automatic :: denom
            integer(kind=i4) :: j
#endif            
            !dir$ attributes align : 64 :: z1
            !dir$ attributes align : 64 :: z2
            !dir$ attributes align : 64 :: num
            !dir$ attributes align : 64 :: den
            !dir$ attributes align : 64 :: cost
#if (GMS_EXPLICIT_VECTORIZE) == 1
            !dir$ attributes align : 64 :: zmm0
            !dir$ attributes align : 64 :: zmm1
            !dir$ attributes align : 64 :: zmm2
            !dir$ attributes align : 64 :: zmm3
            !dir$ attributes align : 64 :: denom
#endif            
            z1 = zi_f716_v512b_ps(tht,mu1,eps1)
            z1 = zi_f716_v512b_ps(tht,mu2,eps2)
#if (GMS_EXPLICIT_VECTORIZE) == 1
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15     
                 cost.v(j) = cos(tht.v(j))
                 num.re(j) = (z2.re(j)*cost.v(j))-z1.re(j) 
                 den.re(j) = (z2.re(j)*cost.v(j))+z2.re(j)
                 num.im(j) = (z2.im(j)*cost.v(j))-z1.im(j)
                 den.im(j) = (z2.im(j)*cost.v(j))+z2.re(j)
                 ! body of cdiv operator
                 zmm0.v(j) = num.re(j)*den.re(j)
                 zmm1.v(j) = num.im(j)*den.im(j)
                 zmm2.v(j) = num.im(j)*den.re(j)
                 zmm3.v(j) = num.re(j)*den.im(j)
                 denom.v(j)= (den.re(j)*den.re(j))+ &
                             (den.im(j)*den.im(j))
                 R.re(j)  =  (zmm0.v(j)+zmm1.v(j))/denom.v(j)
                 R.im(j)  =  (zmm2.v(j)-zmm3.v(j))/denom.v(j)          
             end do
#else
                 cost.v = cos(tht.v)
                 num.re = (z2.re*cost.v)-z1.re
                 den.re = (z2.re*cost.v)+z2.re
                 num.im = (z2.im*cost.v)-z1.im
                 den.im = (z2.im*cost.v)+z2.re
                 R      = num/den
#endif       
        end function R_f7129_v512b_ps
        
        
        !          /*
        !                     For (k1/k2)^2*sin^2(theta)<<1 (Simplification
        !                     of formulae 7.1-9 and 7.1-10).
        !                     Formula 7.1-30
        !!
        !             */

        pure function R_f7130_v512b_ps(tht,mu1,eps1,mu2,eps2) result(R)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: R_f7130_v512b_ps
            !dir$ attributes forceinline :: R_f7130_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: R_f7130_v512b_ps
            type(ZMM16r4_t),  intent(in) :: tht
            type(ZMM16c4),    intent(in) :: mu1
            type(ZMM16c4),    intent(in) :: eps1
            type(ZMM16c4),    intent(in) :: mu2
            type(ZMM16c4),    intent(in) :: eps2
            type(ZMM16c4) :: R
            !Locals
            type(ZMM16c4),   automatic :: z1
            type(ZMM16c4),   automatic :: z2
            type(ZMM16c4),   automatic :: num
            type(ZMM16c4),   automatic :: den
            type(ZMM16c4),   automatic :: t0
            type(ZMM16r4_t), automatic :: cost
#if (GMS_EXPLICIT_VECTORIZE) == 1
            type(ZMM16r4_t), automatic :: zmm0
            type(ZMM16r4_t), automatic :: zmm1
            type(ZMM16r4_t), automatic :: zmm2
            type(ZMM16r4_t), automatic :: zmm3
            type(ZMM16r4_t), automatic :: denom
            integer(kind=i4) :: j
#endif            
            !dir$ attributes align : 64 :: z1
            !dir$ attributes align : 64 :: z2
            !dir$ attributes align : 64 :: num
            !dir$ attributes align : 64 :: den
            !dir$ attributes align : 64 :: t0
            !dir$ attributes align : 64 :: cost  
#if (GMS_EXPLICIT_VECTORIZE) == 1
            !dir$ attributes align : 64 :: zmm0
            !dir$ attributes align : 64 :: zmm1
            !dir$ attributes align : 64 :: zmm2
            !dir$ attributes align : 64 :: zmm3
            !dir$ attributes align : 64 :: denom
#endif 
            z1 = zi_f716_v512b_ps(tht,mu1,eps1)
            z2 = zi_f716_v512b_ps(tht,mu2,eps2)
#if (GMS_EXPLICIT_VECTORIZE) == 1
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15  
                cost.v(j) = cos(tht.v(j))
                t0.re(j)  = z1.re(j)*cost.v(j)
                t0.im(j)  = z1.im(j)*cost.v(j)
                num.re(j) = z2.re(j)-t0.re(j)
                den.re(j) = z2.re(j)+t0.re(j)
                num.im(j) = z2.im(j)-t0.im(j)
                den.im(j) = z2.im(j)+t0.im(j)
                zmm0.v(j) = num.re(j)*den.re(j)
                zmm1.v(j) = num.im(j)*den.im(j)
                zmm2.v(j) = num.im(j)*den.re(j)
                zmm3.v(j) = num.re(j)*den.im(j)
                denom.v(j)= (den.re(j)*den.re(j))+ &
                            (den.im(j)*den.im(j))
                R.re(j)  =  (zmm0.v(j)+zmm1.v(j))/denom.v(j)
                R.im(j)  =  (zmm2.v(j)-zmm3.v(j))/denom.v(j) 
             end do
#else
                cost.v = cos(tht.v)
                t0.re  = z1.re*cost.v
                t0.im  = z1.im*cost.v
                num.re = z2.re-t0.re
                den.re = z2.re+t0.re
                num.im = z2.im-t0.im
                den.im = z2.im+t0.im  
                R      = num/den 
#endif                                  
        end function R_f7130_v512b_ps

        ! /*
        !               Reflection coefficients for (alpha<cos^2(theta)).
        !               Formula 7.2-15
        !          */
        
        pure function R_f7215_to_f7216_v512b_ps(d,k0,alp,tht) result(R)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: R_f7215_to_f7216_v512b_ps
            !dir$ attributes forceinline :: R_f7215_to_f7216_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: R_f7215_to_f7216_v512b_ps
            use mod_fpcompare, only : zmm16r4_equalto_zmm16r4
            use mod_vecconsts, only : v16_1
            type(ZMM16r4_t),   intent(in) :: d
            type(ZMM16r4_t),   intent(in) :: k0
            type(ZMM16r4_t),   intent(in) :: alp
            type(ZMM16r4_t),   intent(in) :: tht
            type(ZMM16r4_t) :: R
            ! Locals
            type(ZMM16r4_t), parameter :: C117549e38 = ZMM16r4_t(1.17549e-38_sp)
            type(ZMM16r4_t), parameter :: C05        = ZMM16r4_t(0.5_sp)
            type(ZMM16r4_t), parameter :: C314159265358979323846264338328 = &
                                                       ZMM16r4_t(3.14159265358979323846264338328_sp)
            
            type(ZMM16r4_t), automatic :: pid2
            type(ZMM16r4_t), automatic :: cost
            type(ZMM16r4_t), automatic :: cos2t
            type(ZMM16r4_t), automatic :: num
            type(ZMM16r4_t), automatic :: den
            type(ZMM16r4_t), automatic :: x0
            type(ZMM16r4_t), automatic :: x1
            type(ZMM16r4_t), automatic :: x2
            type(ZMM16r4_t), automatic :: k
            type(ZMM16r4_t), automatic :: k01a
            type(ZMM16r4_t), automatic :: sin2t
            type(ZMM16r4_t), automatic :: k02k
            type(ZMM16r4_t), automatic :: sqr
            type(Mask16_t),  automatic :: d_eq_C117549e38
            !dir$ attributes align : 64 :: C117549e38
            !dir$ attributes align : 64 :: C05
            !dir$ attributes align : 64 :: C314159265358979323846264338328 
            !dir$ attributes align : 64 :: pid2
            !dir$ attributes align : 64 :: cost
            !dir$ attributes align : 64 :: cos2t
            !dir$ attributes align : 64 :: num
            !dir$ attributes align : 64 :: den
            !dir$ attributes align : 64 :: x0
            !dir$ attributes align : 64 :: x1
            !dir$ attributes align : 64 :: x2
            !dir$ attributes align : 64 :: k
            !dir$ attributes align : 64 :: k01a
            !dir$ attributes align : 64 :: sin2t
            !dir$ attributes align : 64 :: k02k
            !dir$ attributes align : 64 :: sqr
#if (GMS_EXPLICIT_VECTORIZE) == 1
             integer(kind=i4) :: j
#endif
            d_eq_C117549e38 = zmm16r4_equalto_zmm16r4(d,C117549e38)
            if(all(d_eq_C117549e38)==.false.) then
#if (GMS_EXPLICIT_VECTORIZE) == 1
               !dir$ loop_count(16)
               !dir$ vector aligned
               !dir$ vector vectorlength(4)
               !dir$ vector always
               do j=0, 15  
                  pid2.v(j) = C314159265358979323846264338328.v(j)* &
                              d.v(j)*C05.v(j)
                  cost.v(j) = cos(tht.v(j))
                  cos2t.v(j)= (cost.v(j)*cost.v(j))+alp.v(j)
                  x0.v(j)   = sqrt(cos2t.v(j))
                  x1.v(j)   = (pid2.v(j)*cost.v(j))-x0.v(j)
                  num.v(j)  = sinh(x1.v(j))
                  x2.v(j)   = (pid2.v(j)*cost.v(j))+x0.v(j)
                  den.v(j)  = sinh(x2.v(j))
                  R.v(j)    = num.v(j)/den.v(j)
               end do
#else
                  pid2.v = C314159265358979323846264338328.v* &
                              d.v*C05.v
                  cost.v = cos(tht.v)
                  cos2t.v= (cost.v*cost.v)+alp.v
                  x0.v   = sqrt(cos2t.v)
                  x1.v   = (pid2.v*cost.v)-x0.v
                  num.v  = sinh(x1.v)
                  x2.v   = (pid2.v*cost.v)+x0.v
                  den.v  = sinh(x2.v)
                  R.v    = num.v/den.v  
#endif     
            else
#if (GMS_EXPLICIT_VECTORIZE) == 1            
               !dir$ loop_count(16)
               !dir$ vector aligned
               !dir$ vector vectorlength(4)
               !dir$ vector always
               do j=0, 15 
                  k.v(j)    = sqrt(v16_1.v(j)-alp.v(j))
                  cost.v(j) = cos(tht.v(j))
                  k02k.v(j) = (k0.v(j)*k0.v(j))/k.v(j)
                  sint.v(j) = sin(tht.v(j))
                  sin2t.v(j)= sint.v(j)*sint.v(j)
                  x0.v(j)   = v16_1.v(j)-(k02k.v(j)-sin2t.v(j))
                  sqr.v(j)  = sqrt(x0.v(j))
                  x1.v(j)   = k.v(j)*sqr.v(j)
                  num.v(j)  = (k0.v(j)*cost.v(j))-x1.v(j)
                  den.v(j)  = (k0.v(j)*cost.v(j))+x1.v(j)
                  R.v(j)    = num.v(j)/den.v(j)
               end do
#else
                  k.v    = sqrt(v16_1.v-alp.v)
                  cost.v = cos(tht.v)
                  k02k.v = (k0.v*k0.v)/k.v
                  sint.v = sin(tht.v)
                  sin2t.v= sint.v*sint.v
                  x0.v   = v16_1.v-(k02k.v-sin2t.v)
                  sqr.v  = sqrt(x0.v)
                  x1.v   = k.v*sqr.v
                  num.v  = (k0.v*cost.v)-x1.v
                  den.v  = (k0.v*cost.v)+x1.v
                  R.v(j)    = num.v/den.v 
#endif
            end if       
        end function R_f7215_to_f7216_v512b_ps

        ! /*
        !                    Infinite strips, low frequency region.
        !                    E-field (scattered) along 'z'.
        !                    Formula 7.4-1
        !                */
        
        pure function Ezs_f741_v512b_ps(k0,r,a,tht,Ei) result(Es)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: Ezs_f741_v512b_ps
            !dir$ attributes forceinline :: Ezs_f741_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: Ezs_f741_v512b_ps
            use mod_vecconsts, only : v16_1, v16_0
            type(ZMM16r4_t),   intent(in) :: k0
            type(ZMM16r4_t),   intent(in) :: r
            type(ZMM16r4_t),   intent(in) :: a
            type(ZMM16r4_t),   intent(in) :: tht
            type(ZMM16c4),     intent(in) :: Ei
            type(ZMM16c4)  :: Es
            ! Locals
            type(ZMM16r4_t),  parameter :: C17811 = ZMM16r4_t(1.7811_sp)
            type(ZMM16r4_t),  parameter :: C025   = ZMM16r4_t(0.25_sp)
            type(ZMM16r4_t),  parameter :: C314159265358979323846264338328 = &
                                                    ZMM16r4_t(3.14159265358979323846264338328_sp)
            type(ZMM16r4_t),  parameter :: C157079632679489661923132       = &
                                                    ZMM16r4_t(1.57079632679489661923132_sp)
            type(ZMM16r4_t),  parameter :: C4     = ZMM16r4_t(4.0_sp)
            type(ZMM16r4_t),  parameter :: C078539816339744830961566       = &
                                                    ZMM16r4_t(0.78539816339744830961566_sp)
            type(ZMM16c4),    automatic :: den
            type(ZMM16c4),    automatic :: ea
            type(ZMM16c4),    automatic :: ce
            type(ZMM16c4),    automatic :: t0
            type(ZMM16c4),    automatic :: t1
            type(ZMM16r4_t),  automatic :: arg
            type(ZMM16r4_t),  automatic :: num
            type(ZMM16r4_t),  automatic :: k02
            type(ZMM16r4_t),  automatic :: a2
            type(ZMM16r4_t),  automatic :: k0a
            type(ZMM16r4_t),  automatic :: k0r
            type(ZMM16r4_t),  automatic :: cost
            type(ZMM16r4_t),  automatic :: trm
            type(ZMM16r4_t),  automatic :: x0
            type(ZMM16r4_t),  automatic :: x1
            !dir$ attributes align : 64 :: den
            !dir$ attributes align : 64 :: ea
            !dir$ attributes align : 64 :: ce
            !dir$ attributes align : 64 :: t0
            !dir$ attributes align : 64 :: t1
            !dir$ attributes align : 64 :: arg
            !dir$ attributes align : 64 :: num
            !dir$ attributes align : 64 :: k02
            !dir$ attributes align : 64 :: a2
            !dir$ attributes align : 64 :: k0a
            !dir$ attributes align : 64 :: k0r
            !dir$ attributes align : 64 :: cost
            !dir$ attributes align : 64 :: trm
            !dir$ attributes align : 64 :: x0
            !dir$ attributes align : 64 :: x1
#if (GMS_EXPLICIT_VECTORIZE) == 1
            type(ZMM16r4_t), automatic :: tmp
            type(ZMM16r4_t), automatic :: zmm0
            type(ZMM16r4_t), automatic :: zmm1
            type(ZMM16r4_t), automatic :: zmm2
            type(ZMM16r4_t), automatic :: zmm3
            !dir$ attributes align : 64 :: tmp
            !dir$ attributes align : 64 :: zmm0
            !dir$ attributes align : 64 :: zmm1
            !dir$ attributes align : 64 :: zmm2
            !dir$ attributes align : 64 :: zmm3   
            integer(kind=i4) :: j
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15
                den.im(j) = C157079632679489661923132.v(j)
                cost.v(j) = cos(tht.v(j))
                k0r.v(j)  = k0.v(j)*r.v(j)
                a2.v(j)   = a.v(j)*a.v(j)
                ea.re(j)  = v16_0.v(j)
                k0a.v(j)  = k0.v(j)*a.v(j)
                ea.im(j)  = k0r.v(j)+C078539816339744830961566.v(j)
                k02.v(j)  = k0.v(j)*k0.v(j)
                x0.v(j)   = C314159265358979323846264338328.v(j)/ &
                            (k0r.v(j)+k0r.v(j))
                tmp.v(j)  = exp(ea.re(j))
                ce.re(j)  = tmp.v(j)*cos(ea.re(j))
                ce.im(j)  = tmp.v(j)*sin(ea.im(j))
                arg.v(j)  = C4.v(j)/(gam.v(j)*k0a.v(j))
                trm.v(j)  = sqrt(x0.v(j))
                x1.v(j)   = cost.v(j)*cost.v(j)
                den.re(j) = log(arg.v(j))
                x0.v(j)   = k02.v(j)*a2.v(j)*qtr.v(j)+v16_1.v(j)
                num.v(j)  = x0.v(j)*x1.v(j)
                t0.re(j)  = (num.v(j)/den.re(j))*trm.v(j)
                t0.im(j)  = (num.v(j)/den.im(j))*trm.v(j)
                ! Body of operator*
                zmm0.v(j) = t0.re(j)*ce.re(j)
                zmm1.v(j) = t0.im(j)*ce.im(j)
                t1.re(j)  = zmm0.v(j)+zmm1.v(j)
                zmm2.v(j) = t0.im(j)*ce.re(j)
                zmm3.v(j) = t0.re(j)*ce.im(j)
                t1.im(j)  = zmm2.v(j)-zmm3.v(j)
                ! Body of operator*
                zmm0.v(j) = Ei.re(j)*t1.re(j)
                zmm1.v(j) = EI.im(j)*t1.im(j)
                Es.re(j)  = zmm0.v(j)+zmm1.v(j)
                zmm2.v(j) = Ei.im(j)*t1.re(j)
                zmm3.v(j) = Ei.re(j)*ti.im(j)
                Es.im(j)  = zmm2.v(j)-zmm3.v(j)
             end do
            
#else
                den.im = C157079632679489661923132.v
                cost.v = cos(tht.v)
                k0r.v  = k0.v*r.v
                a2.v   = a.v*a.v
                ea.re  = v16_0.v
                k0a.v  = k0.v*a.v
                ea.im  = k0r.v+C078539816339744830961566.v
                k02.v  = k0.v*k0.v
                x0.v   = C314159265358979323846264338328.v/ &
                         (k0r.v+k0r.v)
                ce     = cexp_c16(ea)
                arg.v  = C4.v/(gam.v*k0a.v)
                trm.v  = sqrt(x0.v)
                x1.v   = cost.v*cost.v
                den.re = log(arg.v)
                x0.v   = k02.v*a2.v*qtr.v+v16_1.v
                num.v  = x0.v*x1.v
                t0.re  = (num.v/den.re)*trm.v
                t0.im  = (num.v/den.im)*trm.v
                t1 = t0*ce
                Es = Ei*t1
#endif
        end function Ezs_f741_v512b_ps
        
        !/*
        !                    Infinite strips, low frequency region.
        !                    H-field (scattered) along 'z'.
        !                    Formula 7.4-2
        !                */
        
        pure function Hzs_f742_v512b_ps(k0a,k0r,tht,Hi) result(Hs)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: Hzs_f742_v512b_ps
            !dir$ attributes forceinline :: Hzs_f742_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: Hzs_f742_v512b_ps
            use mod_vecconsts, only : v16_1, v16_0
            type(ZMM16r4_t),    intent(in) :: k0a
            type(ZMM16r4_t),    intent(in) :: k0r
            type(ZMM16r4_t),    intent(in) :: tht
            type(ZMM16c4),      intent(in) :: Hi
            type(ZMM16c4)  :: Hs
            ! Locals
            type(ZMM16r4_t),  parameter :: C0125 = ZMM16r4_t(0.125_sp)
            type(ZMM16r4_t),  parameter :: C314159265358979323846264338328 = &
                                                    ZMM16r4_t(3.14159265358979323846264338328_sp)
            type(ZMM16r4_t),  parameter :: C078539816339744830961566       = &
                                                    ZMM16r4_t(0.78539816339744830961566_sp)
            type(ZMM16c4),    automatic :: ea
            type(ZMM16c4),    automatic :: ce
            type(ZMM16c4),    automatic :: t0
            type(ZMM16c4),    automatic :: ctmp
            type(ZMM16r4_t),  automatic :: trm
            type(ZMM16r4_t),  automatic :: num
            type(ZMM16r4_t),  automatic :: cost
            type(ZMM16r4_t),  automatic :: x0
            type(ZMM16r4_t),  automatic :: x1
            !dir$ attributes align : 64 :: C0125
            !dir$ attributes align : 64 :: C314159265358979323846264338328
            !dir$ attributes align : 64 :: C078539816339744830961566 
            !dir$ attributes align : 64 :: ea
            !dir$ attributes align : 64 :: ce
            !dir$ attributes align : 64 :: t0
            !dir$ attributes align : 64 :: trm
            !dir$ attributes align : 64 :: num
            !dir$ attributes align : 64 :: cost
            !dir$ attributes align : 64 :: x0
            !dir$ attributes align : 64 :: x1
#if (GMS_EXPLICIT_VECTORIZE) == 1
            type(ZMM16r4_t), automatic :: tmp
            type(ZMM16r4_t), automatic :: zmm0
            type(ZMM16r4_t), automatic :: zmm1
            type(ZMM16r4_t), automatic :: zmm2
            type(ZMM16r4_t), automatic :: zmm3
            !dir$ attributes align : 64 :: tmp
            !dir$ attributes align : 64 :: zmm0
            !dir$ attributes align : 64 :: zmm1
            !dir$ attributes align : 64 :: zmm2
            !dir$ attributes align : 64 :: zmm3   
            integer(kind=i4) :: j
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15
                ea.re(j)  = v16_0.v(j)
                cost.v(j) = cos(tht.v(j))
                ea.im(j)  = k0r.v(j)+C078539816339744830961566.v(j)
                x0.v(j)   = C314159265358979323846264338328.v(j)/ &
                            (k0r.v(j)+k0r.v(j))
                tmp.v(j)  = exp(ea.re(j))
                ce.re(j)  = tmp.v(j)*cos(ea.re(j))
                ce.im(j)  = tmp.v(j)*sin(ea.im(j))   
                trm.v(j)  = sqrt(x0.v(j))
                x1.v(j)   = k0a.v(j)+k0a.v(j)
                x0.v(j)   = cost.v(j)*cost.v(j)
                num.v(j)  = x1.v(j)*x1.v(j)*x0.v(j)
                t0.re(j)  = trm.v(j)*ce.re(j)
                t0.im(j)  = trm.v(j)*ce.im(j)
                num.v(j)  = C0125.v(j)*num.v(j)
                x0.v(j)   = Hs.re(j)*num.v(j)
                x1.v(j)   = Hs.im(j)*num.v(j)
                ! Body of operator*
                zmm0.v(j) = x0.re(j)*t0.re(j)
                zmm1.v(j) = x1.im(j)*t0.im(j)
                Hs.re(j)  = zmm0.v(j)+zmm1.v(j)
                zmm2.v(j) = x0.im(j)*t0.re(j)
                zmm3.v(j) = x1.re(j)*t0.im(j)
                Hs.im(j)  = zmm2.v(j)-zmm3.v(j)   
             end do
#else
                ea.re  = v16_0.v
                cost.v = cos(tht.v)
                ea.im  = k0r.v+C078539816339744830961566.v
                x0.v   = C314159265358979323846264338328.v/ &
                            (k0r.v+k0r.v)
                ce     = cexp_c16(ea)  
                trm.v  = sqrt(x0.v)
                x1.v   = k0a.v+k0a.v
                x0.v   = cost.v*cost.v
                num.v  = x1.v*x1.v*x0.v
                t0.re  = trm.v*ce.re
                t0.im  = trm.v*ce.im
                num.v  = C0125.v*num.v
                x0.v   = Hs.re*num.v
                x1.v   = Hs.im*num.v
                ctmp   = zmm16r42x_init(x0,x1)
                Hs     = ctmp*t0
#endif            
        end function Hzs_f742_v512b_ps
        
        !  /*
        !               The resultant backscatter RCS of perpendicular
        !               polarization.
        !               Formula 7.4-3
        !            */
        
        pure function RCS_f743_v512b_ps(k0,a,tht) result(RCS)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: RCS_f743_v512b_ps
            !dir$ attributes forceinline :: RCS_f743_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: RCS_f743_v512b_ps
            use mod_vecconsts, only :  v16_1
            type(ZMM16r4_t),  intent(in) :: k0
            type(ZMM16r4_t),  intent(in) :: a
            type(ZMM16r4_t),  intent(in) :: tht
            type(ZMM16r4_t) :: RCS
            ! Locals
            type(ZMM16r4_t),  parameter :: C9869604401089358618834490999876 = &
                                                ZMM16r4_t(9.869604401089358618834490999876_sp)
            type(ZMM16r4_t),  parameter :: C2467401100272339654708622749969 = &
                                                ZMM16r4_t(2.467401100272339654708622749969_sp)
            type(ZMM16r4_t),  parameter :: C025 = ZMM16r4_t(0.25_sp)
            type(ZMM16r4_t),  parameter :: C448 = ZMM16r4_t(4.48_sp)
            type(ZMM16r4_t),  automatic :: fac
            type(ZMM16r4_t),  automatic :: num
            type(ZMM16r4_t),  automatic :: den
            type(ZMM16r4_t),  automatic :: cost
            type(ZMM16r4_t),  automatic :: k02
            type(ZMM16r4_t),  automatic :: a2
            type(ZMM16r4_t),  automatic :: k0a
            type(ZMM16r4_t),  automatic :: x0
            type(ZMM16r4_t),  automatic :: x1
            type(ZMM16r4_t),  automatic :: arg
            type(ZMM16r4_t),  automatic :: larg
            type(ZMM16r4_t),  automatic :: rat
            !dir$ attributes align : 64 :: C9869604401089358618834490999876
            !dir$ attributes align : 64 :: C2467401100272339654708622749969
            !dir$ attributes align : 64 :: C025
            !dir$ attributes align : 64 :: C448
            !dir$ attributes align : 64 :: fac
            !dir$ attributes align : 64 :: num
            !dir$ attributes align : 64 :: den
            !dir$ attributes align : 64 :: cost
            !dir$ attributes align : 64 :: k02
            !dir$ attributes align : 64 :: a2
            !dir$ attributes align : 64 :: k0a
            !dir$ attributes align : 64 :: x0
            !dir$ attributes align : 64 :: x1
            !dir$ attributes align : 64 :: arg
            !dir$ attributes align : 64 :: larg
            !dir$ attributes align : 64 :: rat 
#if (GMS_EXPLICIT_VECTORIZE) == 1
             integer(kind=i4) :: j
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15
                k0a.v(j)  = k0.v(j)*a.v(j)
                fac.v(j)  = C9869604401089358618834490999876.v(j)/ &
                            k0.v(j)
                k02.v(j)  = k0.v(j)*k0.v(j)
                a2.v(j)   = a.v(j)*a.v(j)
                cost.v(j) = cos(tht.v(j))
                x0.v(j)   = (k02.v(j)*a2.v(j)*C025.v(j))+v16_1.v(j)   
                arg.v(j)  = C448.v(j)/(k0a.v(j)+k0a.v(j))
                x1.v(j)   = x0.v(j)*cost.v(j)*cost.v(j)
                larg.v(j) = log(arg.v(j))
                num.v(j)  = x1.v(j)*x1.v(j)
                den.v(j)  = larg.v(j)*larg.v(j)+  &
                            C2467401100272339654708622749969.v(j)
                rat.v(j)  = num.v(j)/den.v(j)
                RCS.v(j)  = fac.v(j)*rat.v(j)
             end do
#else
                k0a.v  = k0.v*a.v
                fac.v  = C9869604401089358618834490999876.v/k0.v
                k02.v  = k0.v*k0.v
                a2.v   = a.v*a.v
                cost.v = cos(tht.v)
                x0.v   = (k02.v*a2.v*C025.v)+v16_1.v  
                arg.v  = C448.v/(k0a.v+k0a.v)
                x1.v  = x0.v*cost.v*cost.v
                larg.v = log(arg.v)
                num.v  = x1.v*x1.v
                den.v  = larg.v*larg.v+  &
                            C2467401100272339654708622749969.v
                rat.v  = num.v/den.v
                RCS.v  = fac.v*rat.v
#endif            
        end function RCS_f743_v512b_ps

       !  /*
       !                 
       !                The resultant backscatter RCS of parallel
       !                polarization.
       !                Formula 7.4-4  
       !!
       !              */
       
       pure function RCS_f744_v512b_ps(k0,a,tht) result(RCS)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: RCS_f744_v512b_ps
            !dir$ attributes forceinline :: RCS_f744_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: RCS_f744_v512b_ps
            type(ZMM16r4_t),  intent(in) :: k0
            type(ZMM16r4_t),  intent(in) :: a
            type(ZMM16r4_t),  intent(in) :: tht
            type(ZMM16r4_t) :: RCS
            ! Locals
            type(ZMM16r4_t),  parameter :: C9869604401089358618834490999876 = &
                                                ZMM16r4_t(9.869604401089358618834490999876_sp)
            type(ZMM16r4_t),  parameter :: C0015625 = ZMM16r4_t(0.015625_sp)
            type(ZMM16r4_t),  automatic :: k0a
            type(ZMM16r4_t),  automatic :: k0a2
            type(ZMM16r4_t),  automatic :: x0
            type(ZMM16r4_t),  automatic :: x1
            type(ZMM16r4_t),  automatic :: x2
            type(ZMM16r4_t),  automatic :: cost
            type(ZMM16r4_t),  automatic :: cos2t
            type(ZMM16r4_t),  automatic :: fac
            type(ZMM16r4_t),  automatic :: num
            !dir$ attributes align : 64 :: C9869604401089358618834490999876
            !dir$ attributes align : 64 :: C0015625
            !dir$ attributes align : 64 :: k0a
            !dir$ attributes align : 64 :: k0a2
            !dir$ attributes align : 64 :: x0
            !dir$ attributes align : 64 :: x1
            !dir$ attributes align : 64 :: x2
            !dir$ attributes align : 64 :: cost
            !dir$ attributes align : 64 :: cos2t
            !dir$ attributes align : 64 :: fac
            !dir$ attributes align : 64 :: num
#if (GMS_EXPLICIT_VECTORIZE) == 1
             integer(kind=i4) :: j
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15
                k0a.v(j)  = k0.v(j)*a.v(j)
                cost.v(j) = cos(tht.v(j))
                k0a2.v(j) = k0a.v(j)+k0a.v(j)
                fac.v(j)  = C9869604401089358618834490999876.v(j)/ &
                            k0.v(j)
                x2.v(j)   = cos2t.v(j)*cos2t.v(j)
                x0.v(j)   = k0a2.v(j)*k0a2.v(j)
                x1.v(j)   = x0.v(j)*x0.v(j)
                num.v(j)  = (x1.v(j)*x2.v(j))*C0015625.v(j)
                RCS.v(j)  = fac.v(j)*num.v(j)    
             end do
#else
                k0a.v  = k0.v*a.v
                cost.v = cos(tht.v)
                k0a2.v = k0a.v+k0a.v
                fac.v  = C9869604401089358618834490999876.v/ &
                            k0.v
                x2.v   = cos2t.v*cos2t.v
                x0.v   = k0a2.v*k0a2.v
                x1.v   = x0.v*x0.v
                num.v  = (x1.v*x2.v)*C0015625.v
                RCS.v  = fac.v*num.v  
#endif            
       end function RCS_f744_v512b_ps
        
       
      !            /*
      !                    General bistatic case.
      !                    The Rayleigh scattering results.
      !                    Plane-perpendicular.
      !                    Formula 7.4-5
      !               */

      pure function RCS_f745_v512b_ps(k0,a,tht,tht2) result(RCS)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: RCS_f745_v512b_ps
            !dir$ attributes forceinline :: RCS_f745_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: RCS_f745_v512b_ps
            use mod_vecconsts, only :  v16_1
            type(ZMM16r4_t),  intent(in) :: k0
            type(ZMM16r4_t),  intent(in) :: a
            type(ZMM16r4_t),  intent(in) :: tht
            type(ZMM16r4_t),  intent(in) :: tht2
            type(ZMM16r4_t) :: RCS
            type(ZMM16r4_t),  parameter :: C9869604401089358618834490999876 = &
                                                ZMM16r4_t(9.869604401089358618834490999876_sp)
            type(ZMM16r4_t),  parameter :: C2467401100272339654708622749969 = &
                                                ZMM16r4_t(2.467401100272339654708622749969_sp)
            type(ZMM16r4_t),  parameter :: C025 = ZMM16r4_t(0.25_sp)
            type(ZMM16r4_t),  parameter :: C448 = ZMM16r4_t(4.48_sp)
            type(ZMM16r4_t),  automatic :: fac
            type(ZMM16r4_t),  automatic :: num
            type(ZMM16r4_t),  automatic :: den
            type(ZMM16r4_t),  automatic :: cost
            type(ZMM16r4_t),  automatic :: k02
            type(ZMM16r4_t),  automatic :: a2
            type(ZMM16r4_t),  automatic :: k0a
            type(ZMM16r4_t),  automatic :: x0
            type(ZMM16r4_t),  automatic :: x1
            type(ZMM16r4_t),  automatic :: arg
            type(ZMM16r4_t),  automatic :: larg
            type(ZMM16r4_t),  automatic :: rat
            type(ZMM16r4_t),  automatic :: cost2
            !dir$ attributes align : 64 :: C9869604401089358618834490999876
            !dir$ attributes align : 64 :: C2467401100272339654708622749969
            !dir$ attributes align : 64 :: C025
            !dir$ attributes align : 64 :: C448
            !dir$ attributes align : 64 :: fac
            !dir$ attributes align : 64 :: num
            !dir$ attributes align : 64 :: den
            !dir$ attributes align : 64 :: cost
            !dir$ attributes align : 64 :: k02
            !dir$ attributes align : 64 :: a2
            !dir$ attributes align : 64 :: k0a
            !dir$ attributes align : 64 :: x0
            !dir$ attributes align : 64 :: x1
            !dir$ attributes align : 64 :: arg
            !dir$ attributes align : 64 :: larg
            !dir$ attributes align : 64 :: rat
            !dir$ attributes align : 64 :: cost2
#if (GMS_EXPLICIT_VECTORIZE) == 1
             integer(kind=i4) :: j
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15
                  k0a.v(j)  = k0.v(j)*a.v(j)
                  fac.v(j)  = C9869604401089358618834490999876.v(j)/ &
                              k0.v(j)
                  k02.v(j)  = k0.v(j)*k0.v(j)
                  a2.v(j)   = a.v(j)*a.v(j)
                  cost.v(j) = cos(tht.v(j))
                  x0.v(j)   = k02.v(j)*a2.v(j)*C025.v(j)+v16_1.v(j)
                  cost2.v(j)= cos(tht2.v(j))
                  arg.v(j)  = C448.v(j)/(k0a.v(j)+k0a.v(j))
                  x1.v(j)   = x0.v(j)*cost.v(j)*cost2.v(j)
                  larg.v(j) = log(arg.v(j))
                  num.v(j)  = x1.v(j)*x.v(j)
                  den.v(j)  = larg.v(j)*larg.v(j)+ &
                              C2467401100272339654708622749969.v(j)
                  rat.v(j)  = num.v(j)/den.v(j)
                  RCS.v(j)  = fac.v(j)*rat.v(j)
             end do   
#else
                  k0a.v  = k0.v*a.v
                  fac.v  = C9869604401089358618834490999876.v/ &
                              k0.v
                  k02.v  = k0.v*k0.v
                  a2.v   = a.v*a.v
                  cost.v = cos(tht.v)
                  x0.v   = k02.v*a2.v*C025.v+v16_1.v
                  cost2.v= cos(tht2.v)
                  arg.v  = C448.v/(k0a.v+k0a.v)
                  x1.v   = x0.v*cost.v*cost2.v
                  larg.v = log(arg.v)
                  num.v  = x1.v*x.v
                  den.v  = larg.v*larg.v+ &
                              C2467401100272339654708622749969.v
                  rat.v  = num.v/den.v
                  RCS.v  = fac.v*rat.v
#endif         
      end function RCS_f745_v512b_ps
      
     !  /*
     !                     General bistatic case.
     !                     The Rayleigh scattering results.
     !                     Plane-parallel.
     !                     Formula 7.4-6
     !                */
     
      pure function RCS_f746_v512b_ps(k0,a,tht,tht2) result(RCS)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: RCS_f746_v512b_ps
            !dir$ attributes forceinline :: RCS_f746_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: RCS_f746_v512b_ps
            type(ZMM16r4_t),  intent(in) :: k0
            type(ZMM16r4_t),  intent(in) :: a
            type(ZMM16r4_t),  intent(in) :: tht
            type(ZMM16r4_t),  intent(in) :: tht2
            type(ZMM16r4_t) :: RCS
            type(ZMM16r4_t),  parameter :: C9869604401089358618834490999876 = &
                                                ZMM16r4_t(9.869604401089358618834490999876_sp)
            type(ZMM16r4_t),  parameter :: C0015625 = ZMM16r4_t(0.015625_sp)
            type(ZMM16r4_t),  automatic :: k0a
            type(ZMM16r4_t),  automatic :: k0a2
            type(ZMM16r4_t),  automatic :: cost
            type(ZMM16r4_t),  automatic :: cos2t
            type(ZMM16r4_t),  automatic :: fac
            type(ZMM16r4_t),  automatic :: cost2
            type(ZMM16r4_t),  automatic :: x0
            type(ZMM16r4_t),  automatic :: x1
            type(ZMM16r4_t),  automatic :: num
            type(ZMM16r4_t),  automatic :: x2
            !dir$ attributes align : 64 :: C9869604401089358618834490999876
            !dir$ attributes align : 64 :: C0015625
            !dir$ attributes align : 64 :: k0a
            !dir$ attributes align : 64 :: k0a2
            !dir$ attributes align : 64 :: cost
            !dir$ attributes align : 64 :: cos2t
            !dir$ attributes align : 64 :: fac    
            !dir$ attributes align : 64 :: cost2
            !dir$ attributes align : 64 :: x0
            !dir$ attributes align : 64 :: x1
            !dir$ attributes align : 64 :: num
            !dir$ attributes align : 64 :: x2
#if (GMS_EXPLICIT_VECTORIZE) == 1
             integer(kind=i4) :: j
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15
                k0a.v(j)  = k0.v(j)*a.v(j)
                cost.v(j) = cos(tht.v(j))
                k0a2.v(j) = k0a.v(j)+k0a.v(j)
                cost2.v(j)= cos(tht2.v(j))
                fac.v(j)  = C9869604401089358618834490999876.v(j)/k0.v(j)
                x2.v(j)   = (cost2.v(j)*cost2.v(j))* &
                            (cos2t.v(j)*cos2t.v(j))
                x0.v(j)   = k0a2.v(j)*k0a2.v(j)
                x1.v(j)   = x0.v(j)*x0.v(j)
                num.v(j)  = (x2.v(j)*x2.v(j))*C0015625.v(j)
                RCS.v(j)  = fac.v(j)*num.v(j)
             end do
#else
                k0a.v  = k0.v*a.v
                cost.v = cos(tht.v)
                k0a2.v = k0a.v+k0a.v
                cost2.v= cos(tht2.v)
                fac.v  = C9869604401089358618834490999876.v/k0.v
                x2.v   = (cost2.v*cost2.v)* &
                            (cos2t.v*cos2t.v)
                x0.v   = k0a2.v*k0a2.v
                x1.v   = x0.v*x0.v
                num.v  = (x2.v*x2.v)*C0015625.v
                RCS.v  = fac.v*num.v
#endif                                   
      end function RCS_f746_v512b_ps                             

      ! /*
       !                  High Frequency Region.
      !                   For k0a>>1, PO solution of backscatter RCS.
      !                   Formula 7.4-7
       !              */
      
       pure function RCS_f747_v512b_ps(k0,a,tht) result(RCS)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: RCS_f747_v512b_ps
            !dir$ attributes forceinline :: RCS_f747_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: RCS_f747_v512b_ps
            use mod_vecconsts, only :  v16_1
            type(ZMM16r4_t),  intent(in) :: k0
            type(ZMM16r4_t),  intent(in) :: a
            type(ZMM16r4_t),  intent(in) :: tht
            type(ZMM16r4_t) :: RCS
            type(ZMM16r4_t), automatic :: invk0
            type(ZMM16r4_t), automatic :: k0a
            type(ZMM16r4_t), automatic :: cost
            type(ZMM16r4_t), automatic :: sint
            type(ZMM16r4_t), automatic :: arg
            type(ZMM16r4_t), automatic :: sarg
            type(ZMM16r4_t), automatic :: num
            type(ZMM16r4_t), automatic :: sqr
            type(ZMM16r4_t), automatic :: x0
            !dir$ attributes align : 64 :: invk0
            !dir$ attributes align : 64 :: k0a
            !dir$ attributes align : 64 :: cost
            !dir$ attributes align : 64 :: sint
            !dir$ attributes align : 64 :: arg
            !dir$ attributes align : 64 :: sarg
            !dir$ attributes align : 64 :: num
            !dir$ attributes align : 64 :: sqr
            !dir$ attributes align : 64 :: x0
#if (GMS_EXPLICIT_VECTORIZE) == 1
             integer(kind=i4) :: j
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15
                k0a.v(j)   = k0.v(j)*a.v(j)
                cost.v(j)  = cos(tht.v(j))
                invk0.v(j) = v16_1.v(j)/k0.v(j)
                sint.v(j)  = sin(tht.v(j))
                arg.v(j)   = (k0a.v(j)+k0a.v(j))*sint.v(j)
                sarg.v(j)  = sin(arg.v(j))
                num.v(j)   = cost.v(j)*sarg.v(j)
                x0.v(j)    = num.v(j)/sint.v(j)
                sqr.v(j)   = x0.v(j)*x0.v(j)
                RCS.v(j)   = invk0.v(j)*sqr.v(j)        
             end do
#else
                k0a.v   = k0.v*a.v
                cost.v  = cos(tht.v)
                invk0.v = v16_1.v/k0.v
                sint.v  = sin(tht.v)
                arg.v   = (k0a.v+k0a.v)*sint.v
                sarg.v  = sin(arg.v)
                num.v   = cost.v*sarg.v
                x0.v    = num.v/sint.v
                sqr.v   = x0.v*x0.v
                RCS.v   = invk0.v*sqr.v   
#endif            
       end function RCS_f746_v512b_ps 
      
      ! /*
      !                 Backscattered fields from the edges of strips.
      !                 Helper function for the formula 7.4-9
      !                 Electric-field (over z).
      !                 Formula 7.4-15
      !            */
      
      subroutine CoefG12_f7415_v512b_ps(k0a,tht,gamm1,gamm2)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: CoefG12_f7415_v512b_ps
            !dir$ attributes forceinline :: CoefG12_f7415_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: CoefG12_f7415_v512b_ps
            type(ZMM16r4_t),   intent(in)  :: k0a
            type(ZMM16r4_t),   intent(in)  :: tht
            type(ZMM16r4_t),   intent(out) :: gamm1
            type(ZMM16r4_t),   intent(out) :: gamm2
            ! Locals
            type(ZMM16r4_t),  parameter :: C0318309886183790671537767526745 =  &
                                           ZMM16r4_t(0.318309886183790671537767526745_sp)
            type(ZMM16r4_t),  parameter :: C078539816339744830961566084582  =  &
                                           ZMM16r4_t(0.78539816339744830961566084582_sp)
            type(ZMM16r4_t),  parameter :: C05 = ZMM16r4_t(0.5_sp)
            type(ZMM16r4_t),  automatic :: thth
            type(ZMM16r4_t),  automatic :: arg1
            type(ZMM16r4_t),  automatic :: arg2
            type(ZMM16r4_t),  automatic :: carg1
            type(ZMM16r4_t),  automatic :: carg2
            type(ZMM16r4_t),  automatic :: sqr
            type(ZMM16r4_t),  automatic :: x0
            !dir$ attributes align : 64 ::  C0318309886183790671537767526745
            !dir$ attributes align : 64 ::  C078539816339744830961566084582
            !dir$ attributes align : 64 ::  thth
            !dir$ attributes align : 64 ::  arg1
            !dir$ attributes align : 64 ::  arg2
            !dir$ attributes align : 64 ::  carg1
            !dir$ attributes align : 64 ::  carg2
            !dir$ attributes align : 64 ::  sqr
            !dir$ attributes align : 64 ::  x0
#if (GMS_EXPLICIT_VECTORIZE) == 1
             integer(kind=i4) :: j
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15
                x0.v(j)   = k0a.v(j)+k0a.v(j)
                thth.v(j) = C05.v(j)*tht.v(j)
                sqr.v(j)  = sqr(x0.v(j)*C0318309886183790671537767526745.v(j))
                arg1.v(j) = C078539816339744830961566084582.v(j)+thth.v(j)
                carg1.v(j)= cos(arg1.v(j))
                x0.v(j)   = sqr.v(j)+sqr.v(j)
                arg2.v(j) = C078539816339744830961566084582.v(j)+thth.v(j)
                carg2.v(j)= cos(arg2.v(j))
                gamm1.v(j)= x0.v(j)*abs(carg1.v(j))
                gamm2.v(j)= x0.v(j)*abs(carg2.v(j))
             end do
#else
                x0.v   = k0a.v+k0a.v
                thth.v = C05.v*tht.v
                sqr.v  = sqr(x0.v*C0318309886183790671537767526745.v)
                arg1.v = C078539816339744830961566084582.v+thth.v
                carg1.v= cos(arg1.v)
                x0.v   = sqr.v+sqr.v
                arg2.v = C078539816339744830961566084582.v+thth.v
                carg2.v= cos(arg2.v)
                gamm1.v= x0.v*abs(carg1.v)
                gamm2.v= x0.v*abs(carg2.v)
#endif                 
      end subroutine CoefG12_f7415_v512b_ps
      
      
      !                /*
      !                 Backscattered fields from the edges of strips.
      !                 Helper function for the formula 7.4-9
      !                 Electric-field (over z).
       !                Formula 7.4-13
      !            */
      
      subroutine CoefA12_f7413_v512b_ps(k0a,tht,A1,A2)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: CoefA12_f7413_v512b_ps
            !dir$ attributes forceinline :: CoefA12_f7413_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: CoefA12_f7413_v512b_ps
            use rcs_common_zmm16r4, only : fresnel_S_zmm16r4, fresnel_C_zmm16r4
            use mod_vecconsts,      only :  v16_0
            type(ZMM16r4_t),   intent(in)  :: k0a
            type(ZMM16r4_t),   intent(in)  :: tht
            type(ZMM16c4),     intent(out) :: A1
            type(ZMM16c4),     intent(out) :: A2
            ! Locals
            type(ZMM16r4_t),  parameter :: C078539816339744830961566084582 = &
                                                ZMM16r4_t(-0.78539816339744830961566084582_sp)
            type(ZMM16r4_t),  parameter :: C141421356237309504880168872421 = &
                                                ZMM16r4_t(1.41421356237309504880168872421_sp)
            type(ZMM16c4),    automatic :: ea
            type(ZMM16c4),    automatic :: ce
            type(ZMM16c4),    automatic :: ct0
            type(ZMM16c4),    automatic :: ct1
            type(ZMM16r4_t),  automatic :: Cr1
            type(ZMM16r4_t),  automatic :: Si1
            type(ZMM16r4_t),  automatic :: Cr2
            type(ZMM16r4_t),  automatic :: Si2
            type(ZMM16r4_t),  automatic :: gam1
            type(ZMM16r4_t),  automatic :: gam2
            !dir$ attributes align : 64 :: C078539816339744830961566084582
            !dir$ attributes align : 64 :: C141421356237309504880168872421
            !dir$ attributes align : 64 :: ea
            !dir$ attributes align : 64 :: ce
            !dir$ attributes align : 64 :: Cr1
            !dir$ attributes align : 64 :: Si1
            !dir$ attributes align : 64 :: Cr2
            !dir$ attributes align : 64 :: Si2
            !dir$ attributes align : 64 :: gam1
            !dir$ attributes align : 64 :: gam2
#if (GMS_EXPLICIT_VECTORIZE) == 1
            type(ZMM16r4_t),  automatic :: t0
            type(ZMM16r4_t), automatic :: zmm0
            type(ZMM16r4_t), automatic :: zmm1
            type(ZMM16r4_t), automatic :: zmm2
            type(ZMM16r4_t), automatic :: zmm3
            !dir$ attributes align : 64 :: zmm0
            !dir$ attributes align : 64 :: zmm1
            !dir$ attributes align : 64 :: zmm2
            !dir$ attributes align : 64 :: zmm3   
            !dir$ attributes align : 64 :: t0
             integer(kind=i4) :: j
#endif
             call CoefG12_f7415_v512b_ps(k0a,tht,gamm1,gamm2)
             Cr1  =   fresnel_C_zmm16r4(gam1)
             Si1  =   fresnel_S_zmm16r4(gam1)
             Cr2  =   fresnel_C_zmm16r4(gam2)
             Si2  =   fresnel_S_zmm16r4(gam2)
#if (GMS_EXPLICIT_VECTORIZE) == 1
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15
                ea.re(j)  = v16_0.v(j)
                ea.im(j)  = C078539816339744830961566084582.v(j)
                t0.v(j)   = exp(ea.re(j))
                ce.re(j)  = t0.v(j)*cos(ea.re(j))
                ce.im(j)  = t0.v(j)*sin(ea.im(j))
                ce.re(j)  = ce.re(j)*C141421356237309504880168872421.v(j)
                ce.im(j)  = ce.im(j)*C141421356237309504880168872421.v(j)
                ! Body of operator*
                zmm0.v(j) = ce.re(j)*Cr1.v(j)
                zmm1.v(j) = ce.im(j)*Si1.v(j)
                A1.re(j)  = zmm0.v(j)+zmm1.v(j)
                zmm2.v(j) = ce.im(j)*Cr1.re(j)
                zmm3.v(j) = ce.re(j)*Si1.im(j)
                A1.im(j)  = zmm2.v(j)-zmm3.v(j)   
                ! Body of operator*
                zmm0.v(j) = ce.re(j)*Cr2.v(j)
                zmm1.v(j) = ce.im(j)*Si2.v(j)
                A2.re(j)  = zmm0.v(j)+zmm1.v(j)
                zmm2.v(j) = ce.im(j)*Cr2.re(j)
                zmm3.v(j) = ce.re(j)*Si2.im(j)
                A2.im(j)  = zmm2.v(j)-zmm3.v(j)  
             end do
#else
                ea.re  = v16_0.v
                ea.im  = C078539816339744830961566084582.v
                ce     = cexp_c16(ea)
                ct0    = zmm16r42x_init(Cr1,Si1)
                ce.re  = ce.re*C141421356237309504880168872421.v
                ce.im  = ce.im*C141421356237309504880168872421.v
                ct1    = zmm16r42x_init(Cr2,Si2)
                A1     = ce*ct0
                A2     = ce*ct1
#endif
                
      end subroutine CoefA12_f7413_v512b_ps
      
      ! /*
      !                 Backscattered fields from the edges of strips.
      !                 Helper function for the formula 7.4-9
      !                 Electric-field (over z).
      !                 Formula 7.4-14
      !            */
      
      subroutine CoefB12_f7414_v512b_ps(k0a,tht,B1,B2)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: CoefB12_f7414_v512b_ps
            !dir$ attributes forceinline :: CoefB12_f7414_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: CoefB12_f7414_v512b_ps
            use mod_vecconsts,      only :  v16_0, v16_1
            type(ZMM16r4_t),   intent(in)  :: k0a
            type(ZMM16r4_t),   intent(in)  :: tht
            type(ZMM16c4),     intent(out) :: B1
            type(ZMM16c4),     intent(out) :: B2
            ! Locals
            type(ZMM16r4_t),  parameter :: C078539816339744830961566084582 = &
                                                ZMM16r4_t(-0.78539816339744830961566084582_sp)
            type(ZMM16r4_t),  parameter :: C314159265358979323846264338328 = &
                                                ZMM16r4_t(3.14159265358979323846264338328_sp)
            type(ZMM16r4_t),  parameter :: C05 = ZMM16r4_t(0.5_sp)    
            type(ZMM16c4),    automatic :: A1
            type(ZMM16c4),    automatic :: A2                               
            type(ZMM16c4),    automatic :: ea1
            type(ZMM16c4),    automatic :: ea2
            type(ZMM16c4),    automatic :: ce1
            type(ZMM16c4),    automatic :: ce2
            type(ZMM16c4),    automatic :: I
            type(ZMM16c4),    automatic :: t0
            type(ZMM16c4),    automatic :: t1
            type(ZMM16c4),    automatic :: ctmp1
            type(ZMM16c4),    automatic :: ctmp2
            type(ZMM16r4_t),  automatic :: sint
            type(ZMM16r4_t),  automatic :: htht
            type(ZMM16r4_t),  automatic :: carg1
            type(ZMM16r4_t),  automatic :: carg2
            type(ZMM16r4_t),  automatic :: arg1
            type(ZMM16r4_t),  automatic :: arg2
            type(ZMM16r4_t),  automatic :: abs1
            type(ZMM16r4_t),  automatic :: abs2
            type(ZMM16r4_t),  automatic :: x0
            type(ZMM16r4_t),  automatic :: x1
            type(ZMM16r4_t),  automatic :: x2
            type(ZMM16r4_t),  automatic :: x3
            type(ZMM16r4_t),  automatic :: x4
            type(ZMM16r4_t),  automatic :: x5            
            type(ZMM16r4_t),  automatic :: k0a2
            !dir$ attributes align : 64 ::  C078539816339744830961566084582
            !dir$ attributes align : 64 ::  C314159265358979323846264338328
            !dir$ attributes align : 64 ::  A1
            !dir$ attributes align : 64 ::  A2
            !dir$ attributes align : 64 ::  C05
            !dir$ attributes align : 64 ::  ea1
            !dir$ attributes align : 64 ::  ea2
            !dir$ attributes align : 64 ::  ce1
            !dir$ attributes align : 64 ::  ce2
            !dir$ attributes align : 64 ::  I
            !dir$ attributes align : 64 ::  t0
            !dir$ attributes align : 64 ::  t1
            !dir$ attributes align : 64 ::  ctmp1
            !dir$ attributes align : 64 ::  ctmp2
            !dir$ attributes align : 64 ::  sint
            !dir$ attributes align : 64 ::  htht
            !dir$ attributes align : 64 ::  carg1
            !dir$ attributes align : 64 ::  carg2
            !dir$ attributes align : 64 ::  arg1
            !dir$ attributes align : 64 ::  arg2
            !dir$ attributes align : 64 ::  abs1
            !dir$ attributes align : 64 ::  abs2
            !dir$ attributes align : 64 ::  x0
            !dir$ attributes align : 64 ::  x1
            !dir$ attributes align : 64 ::  x2
            !dir$ attributes align : 64 ::  x3
            !dir$ attributes align : 64 ::  x4
            !dir$ attributes align : 64 ::  x5
            !dir$ attributes align : 64 ::  k0a2
#if (GMS_EXPLICIT_VECTORIZE) == 1
            type(ZMM16r4_t),  automatic :: ct0
            type(ZMM16r4_t), automatic :: zmm0
            type(ZMM16r4_t), automatic :: zmm1
            type(ZMM16r4_t), automatic :: zmm2
            type(ZMM16r4_t), automatic :: zmm3
            !dir$ attributes align : 64 :: zmm0
            !dir$ attributes align : 64 :: zmm1
            !dir$ attributes align : 64 :: zmm2
            !dir$ attributes align : 64 :: zmm3   
            !dir$ attributes align : 64 :: ct0
             integer(kind=i4) :: j
#endif                   
            call CoefA12_f7413_v512b_ps(k0a,tht,A1,A2)
#if (GMS_EXPLICIT_VECTORIZE) == 1
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15
                I.re(j)    = v16_0.v(j)
                x0.v(j)    = sqrt(C314159265358979323846264338328.v(j)* &
                                  k0a.v(j))
                htht.v(j)  = C05.v(j)*tht.v(j)
                ea1.re(j)  = I.re(j)
                sint.v(j)  = sin(tht.v(j))
                I.im(j)    = x0.v(j)+x0.v(j)
                k0a2.v(j)  = k0a.v(j)+k0a.v(j)
                x0.v(j)    = v16_1.v(j)+sint.v(j)
                ea2.im(j)  = (k0a2.v(j)*x0.v(j))- &
                              C078539816339744830961566084582.v(j)
                ! complex exp
                ct0.v(j)   = exp(ea1.re(j))
                ce1.re(j)  = ct0.v(j)*cos(ea1.re(j))
                ce1.im(j)  = ct0.v(j)*sin(ea2.im(j))
                arg1.v(j)  = C078539816339744830961566084582.v(j)- &
                             htht.v(j)
                carg1.v(j) = cos(arg1.v(j))
                x1.v(j)    = v16_1.v(j)-sint.v(j)
                ea1.im(j)  = (k0a2.v(j)*x1.v(j))- &
                             C078539816339744830961566084582.v(j)
                ! complex exp
                ct0.v(j)   = exp(ea1.re(j))
                ce2.re(j)  = ct0.v(j)*cos(ea1.re(j))
                ce2.im(j)  = ct0.v(j)*sin(ea1.im(j)) 
                abs1.v(j)  = abs(carg1.v(j))
                t0.re(j)   = ce2.re(j)/abs1.v(j)
                arg2.v(j)  = C078539816339744830961566084582.v(j)/ &
                             htht.v(j)
                t0.im(j)   = ce2.im(j)/abs1.v(j)
                carg2.v(j) = cos(arg2.v(j))
                abs2.v(j)  = abs(carg2.v(j))
                t1.re(j)   = ce1.re(j)/abs2.v(j)
                ! Body of operator*
                zmm0.v(j) = I.re(j)*t0.re(j)
                zmm1.v(j) = I.im(j)*t0.im(j)
                x2.v(j)   = zmm0.v(j)+zmm1.v(j)
                zmm2.v(j) = I.im(j)*t0.re(j)
                zmm3.v(j) = I.re(j)*t0.im(j)
                x3.v(j)   = zmm2.v(j)-zmm3.v(j)  
                t1.im(j)  = ce1.im(j)/abs2.v(j)
                ! Body of operator*
                zmm0.v(j) = I.re(j)*t1.re(j)
                zmm1.v(j) = I.im(j)*t1.im(j)
                x4.v(j)   = zmm0.v(j)+zmm1.v(j)
                zmm2.v(j) = I.im(j)*t1.re(j)
                zmm3.v(j) = I.re(j)*t1.im(j)
                x5.v(j)   = zmm2.v(j)-zmm3.v(j)  
                B1.re(j)  = A1.re(j)+x2.v(j)
                B2.re(j)  = A2.re(j)+x4.v(j)
                B1.im(j)  = A1.im(j)+x3.v(j)
                B2.im(j)  = A2.im(j)+x5.v(j)
             end do
#else
                I.re    = v16_0.v
                x0.v    = sqrt(C314159265358979323846264338328.v* &
                                  k0a.v)
                htht.v  = C05.v*tht.v
                ea1.re  = I.re
                sint.v  = sin(tht.v)
                I.im    = x0.v+x0.v
                k0a2.v  = k0a.v+k0a.v
                x0.v    = v16_1.v+sint.v
                ea2.im  = (k0a2.v*x0.v)- &
                              C078539816339744830961566084582.v
                ct0.v   = exp(ea1.re)
                ce1.re = ct0.v*cos(ea1.re)
                ce1.im  = ct0.v*sin(ea2.im)
                arg1.v  = C078539816339744830961566084582.v- &
                             htht.v
                carg1.v = cos(arg1.v)
                x1.v    = v16_1.v-sint.v
                ea1.im  = (k0a2.v*x1.v)- &
                             C078539816339744830961566084582.v
                ct0.v   = exp(ea1.re)
                ce2.re  = ct0.v*cos(ea1.re)
                ce2.im  = ct0.v*sin(ea1.im) 
                abs1.v  = abs(carg1.v)
                t0.re   = ce2.re/abs1.v
                arg2.v  = C078539816339744830961566084582.v/ &
                             htht.v
                t0.im   = ce2.im/abs1.v
                carg2.v = cos(arg2.v)
                abs2.v  = abs(carg2.v)
                t1.re   = ce1.re/abs2.v
                ctmp1   = zmm16r42x_init(x2,x3)
                ctmp1   = I*t0
                ctmp2   = zmm16r42x_init(x4,x5)
                ctmp2   = I*t1
                B1.re   = A1.re*x2.v
                B2.re   = A2.re*x4.v
                B1.im   = A1.im*x3.v
                B2.im   = A2.im*x5.v
#endif                          
     end subroutine CoefB12_f7414_v512b_ps
     
     !   /*
     !                  Very Important!!
     !                  Backscattered fields from the edges of strips.
     !                  Ufimtsev derivation.
     !                  Electric-field (over z).
     !                  Formula 7.4-9
     !            */
     
     subroutine Esz_f749_v512b_ps(tht,k0a,k0r,Ei,Es)
            !dir$ optimize:3
            !dir$ attributes code_align : 32 :: Esz_f749_v512b_ps
            !dir$ attributes forceinline :: Esz_f749_v512b_ps
            !dir$ attributes optimization_parameter:"target_arch=skylake-avx512" :: Esz_f749_v512b_ps
            use mod_vecconsts,      only :  v16_1, v16_0
            type(ZMM16r4_t),   intent(in)  :: tht
            type(ZMM16r4_t),   intent(in)  :: k0a
            type(ZMM16r4_t),   intent(in)  :: k0r
            type(ZMM16c4),     intent(in)  :: Ei
            type(ZMM16c4),     intent(out) :: Es
            type(ZMM16r4_t),   parameter :: C078539816339744830961566084582 = &
                                            ZMM16r4_t(0.78539816339744830961566084582_sp)
            type(ZMM16r4_t),   parameter :: C314159265358979323846264338328 = &
                                            ZMM16r4_t(3.14159265358979323846264338328_sp)
            type(ZMM16r4_t),   parameter :: C6283185307179586476925286766559 = &
                                            ZMM16r4_t(6.283185307179586476925286766559_sp)
            type(ZMM16c4),     automatic :: ea1
            type(ZMM16c4),     automatic :: ce1
            type(ZMM16c4),     automatic :: B1
            type(ZMM16c4),     automatic :: B2
            type(ZMM16c4),     automatic :: B1s
            type(ZMM16c4),     automatic :: B2s
            type(ZMM16c4),     automatic :: ea2
            type(ZMM16c4),     automatic :: ea3
            type(ZMM16c4),     automatic :: ce2
            type(ZMM16c4),     automatic :: ce3
            type(ZMM16c4),     automatic :: t0
            type(ZMM16c4),     automatic :: t1
            type(ZMM16c4),     automatic :: t2
            type(ZMM16c4),     automatic :: ctmp
            type(ZMM16r4_t),   automatic :: sint
            type(ZMM16r4_t),   automatic :: sin2t
            type(ZMM16r4_t),   automatic :: sin1
            type(ZMM16r4_t),   automatic :: sin2
            type(ZMM16r4_t),   automatic :: sqr
            type(ZMM16r4_t),   automatic :: x0
            type(ZMM16r4_t),   automatic :: x1
            type(ZMM16r4_t),   automatic :: k0a2
            type(ZMM16r4_t),   automatic :: y0
            !dir$ attributes align : 64 :: C078539816339744830961566084582
            !dir$ attributes align : 64 :: C314159265358979323846264338328
            !dir$ attributes align : 64 :: C6283185307179586476925286766559
            !dir$ attributes align : 64 :: ea1
            !dir$ attributes align : 64 :: ce1
            !dir$ attributes align : 64 :: B1
            !dir$ attributes align : 64 :: B2
            !dir$ attributes align : 64 :: B1s
            !dir$ attributes align : 64 :: B2s
            !dir$ attributes align : 64 :: ea2
            !dir$ attributes align : 64 :: ea3
            !dir$ attributes align : 64 :: ce2
            !dir$ attributes align : 64 :: ce3
            !dir$ attributes align : 64 :: t0
            !dir$ attributes align : 64 :: t1
            !dir$ attributes align : 64 :: t2
            !dir$ attributes align : 64 :: ctmp
            !dir$ attributes align : 64 :: sint
            !dir$ attributes align : 64 :: sin2t
            !dir$ attributes align : 64 :: sin1
            !dir$ attributes align : 64 :: sin2
            !dir$ attributes align : 64 :: sqr
            !dir$ attributes align : 64 :: x0
            !dir$ attributes align : 64 :: x1
            !dir$ attributes align : 64 :: k0a2
            !dir$ attributes align : 64 :: y0
#if (GMS_EXPLICIT_VECTORIZE) == 1
            type(ZMM16r4_t),  automatic :: ct0
            type(ZMM16r4_t), automatic :: zmm0
            type(ZMM16r4_t), automatic :: zmm1
            type(ZMM16r4_t), automatic :: zmm2
            type(ZMM16r4_t), automatic :: zmm3
            !dir$ attributes align : 64 :: zmm0
            !dir$ attributes align : 64 :: zmm1
            !dir$ attributes align : 64 :: zmm2
            !dir$ attributes align : 64 :: zmm3   
            !dir$ attributes align : 64 :: ct0
             integer(kind=i4) :: j
#endif      
            call CoefB12_f7414_v512b_ps(k0a,tht,B1,B2)
#if (GMS_EXPLICIT_VECTORIZE) == 1
             !dir$ loop_count(16)
             !dir$ vector aligned
             !dir$ vector vectorlength(4)
             !dir$ vector always
             do j=0, 15
                ea1.re(j)   = v16_0.v(j)
                sqr.v(j)    = sqrt(C6283185307179586476925286766559.v(j)* &
                                   k0r.v(j))
                k0a2.v(j)   = k0a.v(j)+k0a.v(j)
                ea1.im(j)   = k0r.v(j)+  &
                              C078539816339744830961566084582.v(j)
                sint.v(j)   = sin(tht.v(j))
                 ! complex exp
                ct0.v(j)   = exp(ea1.re(j))
                ce1.re(j)  = ct0.v(j)*cos(ea1.re(j))
                ce1.im(j)  = ct0.v(j)*sin(ea1.im(j))
                sin2t.v(j) = sint.v(j)+sint.v(j)
                sin1.v(j)  = (v16_1.v(j)-sint.v(j))/sin2t.v(j)
                ! operator*
                zmm0.v(j) = B1.re(j)*B1.re(j)
                zmm1.v(j) = B1.im(j)*B1.im(j)
                B1s.re(j) = zmm0.v(j)+zmm1.v(j)
                zmm2.v(j) = B1.im(j)*B1.re(j)
                zmm3.v(j) = B1.re(j)*B1.im(j)
                B1s.im(j) = zmm2.v(j)-zmm3.v(j)
                ea2.re(j) = ea1.re(j)
                sin2.v(j) = (v16_1.v(j)+sint.v(j))/sin2t.v(j)
                y0.v(j)   = k0a2.v(j)*sint.v(j)
                ea2.im(j) = y0.v(j)
                ! complex exp
                ct0.v(j)   = exp(ea2.re(j))
                ce2.re(j)  = ct0.v(j)*cos(ea2.re(j))
                ce2.im(j)  = ct0.v(j)*sin(ea2.im(j))
                ce2.re(j)  = sin1.v(j)*ce2.re(j)
                ce2.im(j)  = sin1.v(j)*ce2.im(j)
                ea3.re(j)  = ea1.re(j)
                ! operator*
                zmm0.v(j) = B2.re(j)*B2.re(j)
                zmm1.v(j) = B2.im(j)*B2.im(j)
                B2s.re(j) = zmm0.v(j)+zmm1.v(j)
                zmm2.v(j) = B2.im(j)*B2.re(j)
                zmm3.v(j) = B2.re(j)*B2.im(j)
                B2s.im(j) = zmm2.v(j)-zmm3.v(j)
                ea3.im(j) = -y0.v(j)
                ! complex exp
                ct0.v(j)   = exp(ea3.re(j))
                ce3.re(j)  = ct0.v(j)*cos(ea3.re(j))
                ce3.im(j)  = ct0.v(j)*sin(ea3.im(j))
                ce3.re(j)  = sin2.v(j)*ce3.re(j)
                ce3.im(j)  = sin2.v(j)*ce3.im(j)
                ! operator*
                zmm0.v(j) = B2s.re(j)*ce2.re(j)
                zmm1.v(j) = B2s.im(j)*ce2.im(j)
                t0.re(j)  = zmm0.v(j)+zmm1.v(j)
                zmm2.v(j) = B2s.im(j)*ce2.re(j)
                zmm3.v(j) = B2s.re(j)*ce2.im(j)
                t0.im(j) = zmm2.v(j)-zmm3.v(j)
                !  operator*
                zmm0.v(j) = B1s.re(j)*ce3.re(j)
                zmm1.v(j) = B1s.im(j)*ce3.im(j)
                t1.re(j)  = zmm0.v(j)+zmm1.v(j)
                zmm2.v(j) = B1s.im(j)*ce3.re(j)
                zmm3.v(j) = B1s.re(j)*ce3.im(j)
                t1.im(j)  = zmm2.v(j)-zmm3.v(j)
                t2.re(j)  = t0.re(j)-t1.re(j)
                t2.im(j)  = t0.im(j)-t1.im(j)
                ! operator*
                zmm0.v(j) = Ei.re(j)*t2.re(j)
                zmm1.v(j) = Ei.im(j)*t2.im(j)
                x0.v(j)   = zmm0.v(j)+zmm1.v(j)
                zmm2.v(j) = Ei.im(j)*t2.re(j)
                zmm3.v(j) = Ei.re(j)*t2.im(j)
                x1.im(j)  = zmm2.v(j)-zmm3.v(j)
                ! operator*
                zmm0.v(j) = x0.v(j)*ce1.re(j)
                zmm1.v(j) = x1.v(j)*ce1.im(j)
                Es.re(j)  = zmm0.v(j)+zmm1.v(j)
                zmm2.v(j) = x1.v(j)*ce1.re(j)
                zmm3.v(j) = x0.v(j)*ce1.im(j)
                Es.im(j)  = zmm2.v(j)-zmm3.v(j)
             end do
#else
                ea1.re   = v16_0.v
                sqr.v    = sqrt(C6283185307179586476925286766559.v* &
                                   k0r.v)
                k0a2.v   = k0a.v+k0a.v
                ea1.im   = k0r.v+  &
                              C078539816339744830961566084582.v
                sint.v   = sin(tht.v)
                ce1      = cexp_c16(ea1)
                sin2t.v  = sint.v+sint.v
                sin1.v   = (v16_1.v-sint.v)/sin2t.v
                B1s      = B1*B1
                ea2.re   = ea1.re
                sin2.v   = (v16_1.v+sint.v)/sin2t.v
                y0.v     = k0a2.v*sint.v
                ea2.im   = y0.v
                ce2      = cexp_c16(ea2)
                ce2.re  = sin1.v*ce2.re
                ce2.im  = sin1.v*ce2.im
                ea3.re  = ea1.re
                B2s     = B2*B2
                ea3.im  = -y0.v
                ce3     = cexp_c16(ea3)
                ce3.re  = sin2.v*ce3.re
                ce3.im  = sin2.v*ce3.im
                t0      = B2s*ce2
                t1      = B1s*ce3
                t2.re   = t0.re-t1.re
                t2.im   = t0.im-t1.im
                ctmp    = zmm16r42x_init(x0,x1)
                ctmp    = Ei*t2
                Es      = ctmp*ce
#endif                     
     end subroutine Esz_f749_v512b_ps













































end module rcs_planar_zmm16r4
