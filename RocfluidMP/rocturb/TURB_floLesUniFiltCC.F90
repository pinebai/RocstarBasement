! *********************************************************************
! * Rocstar Simulation Suite                                          *
! * Copyright@2015, Illinois Rocstar LLC. All rights reserved.        *
! *                                                                   *
! * Illinois Rocstar LLC                                              *
! * Champaign, IL                                                     *
! * www.illinoisrocstar.com                                           *
! * sales@illinoisrocstar.com                                         *
! *                                                                   *
! * License: See LICENSE file in top level of distribution package or *
! * http://opensource.org/licenses/NCSA                               *
! *********************************************************************
! *********************************************************************
! * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,   *
! * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES   *
! * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND          *
! * NONINFRINGEMENT.  IN NO EVENT SHALL THE CONTRIBUTORS OR           *
! * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER       *
! * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   *
! * Arising FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE    *
! * USE OR OTHER DEALINGS WITH THE SOFTWARE.                          *
! *********************************************************************
!******************************************************************************
!
! Purpose: Perform cell to cell uniform filtering.
!
! Description: We treat the filter-operation in three consequtive sweeps
!              corresponding to the three coordinate directions. We use the
!              composite trapezoidal rule. This can be applied directly if
!              ndel=even and leads to integration weights:(1/2,1,..,1,1/2)/ndel
!              i.e. weight 1/2 for the end-points and 1 for the inner points
!              on a uniform grid. If ndel=0 we do not filter at all and if
!              ndel=odd we filter the inner points as usual and use a linear
!              interpolation for the end-intervals. For the weights this
!              implies (1/8,6/8,1/8): ndel=1 and (1/8,7/8,1,..,1,7/8,1/8)/ndel
!              if ndel=odd and > 1. This has an obvious extension for
!              nonuniform grids.
!
! Input: region  = data of current region 
!        nDel    = three components filter width parameter
!        idBeg   = begin variable index to be filtered
!        idEnd   = end variable index to be filtered
!        fVar    = cell variable to be filtered
!
! Output: fbVar  = filtered cell variable
!
! Notes: none.
!
!******************************************************************************
!
! $Id: TURB_floLesUniFiltCC.F90,v 1.5 2008/12/06 08:44:43 mtcampbe Exp $
!
! Copyright: (c) 2001 by the University of Illinois
!
!******************************************************************************

SUBROUTINE TURB_FloLesUniFiltCC( region,nDel,idBeg,idEnd,fVar,fbVar )

  USE ModDataTypes
  USE ModDataStruct, ONLY : t_region
  USE ModGlobal, ONLY     : t_global
  USE ModInterfaces, ONLY : RFLO_GetDimensDummy, RFLO_GetCellOffset
  USE TURB_ModInterfaces, ONLY : TURB_FloLesUniFiltCCI, &
                                 TURB_FloLesUniFiltCCJ, &
                                 TURB_FloLesUniFiltCCK
  USE ModTurbulence
  USE ModError
  USE ModParameters
  USE TURB_ModParameters
  IMPLICIT NONE

#include "Indexing.h"

! ... parameters
  TYPE(t_region)        :: region
  INTEGER               :: nDel(DIRI:DIRK),idBeg,idEnd
  REAL(RFREAL), POINTER :: fVar(:,:),fbVar(:,:)

! ... loop variables
  INTEGER :: i, j, k, l, ijkC

! ... local variables
  CHARACTER(CHRLEN)       :: RCSIdentString
  TYPE(t_global), POINTER :: global

  INTEGER           :: ibeg,iend,jbeg,jend,kbeg,kend
  INTEGER           :: idcbeg,idcend,jdcbeg,jdcend,kdcbeg,kdcend
  INTEGER           :: iLev,iCOff,ijCOff,ibc,iec,nDum

  REAL(RFREAL)      :: fact1(FILWIDTH_FOUR),fact2(FILWIDTH_FOUR)
  REAL(RFREAL), POINTER :: wrkbar(:,:)

!******************************************************************************

  RCSIdentString = '$RCSfile: TURB_floLesUniFiltCC.F90,v $'

  global => region%global
  CALL RegisterFunction( global,'TURB_FloLesUniFiltCC',&
  'TURB_floLesUniFiltCC.F90' )

! get indices, parameters and pointers ----------------------------------------

  nDum = region%nDumCells 
  iLev = region%currLevel
  CALL RFLO_GetDimensDummy( region,iLev,idcbeg,idcend, &
                            jdcbeg,jdcend,kdcbeg,kdcend )
  CALL RFLO_GetCellOffset( region,iLev,iCOff,ijCOff )
  ibc = IndIJK(idcbeg,jdcbeg,kdcbeg,iCOff,ijCOff)
  iec = IndIJK(idcend,jdcend,kdcend,iCOff,ijCOff)

  ALLOCATE( wrkbar(idBeg:idEnd,ibc:iec) )

  fact1(FILWIDTH_ONE)  = 0.125_RFREAL
  fact2(FILWIDTH_ONE)  = 0.75_RFREAL
  fact1(FILWIDTH_TWO)  = 0.25_RFREAL
  fact2(FILWIDTH_TWO)  = 0.50_RFREAL
  fact1(FILWIDTH_FOUR) = 0.125_RFREAL
  fact2(FILWIDTH_FOUR) = 0.25_RFREAL

  ibeg = idcbeg
  iend = idcend
  jbeg = jdcbeg
  jend = jdcend
  kbeg = kdcbeg
  kend = kdcend

! we begin with integration over I-direction

  CALL TURB_FloLesUniFiltCCI( global,nDum,ibeg,iend,jbeg,jend,kbeg,kend, &
                             iCOff,ijCOff,nDel,idBeg,idEnd,fact1,fact2,fVar, &
                             fbVar )

! next, integrate over J-direction

  CALL TURB_FloLesUniFiltCCJ( global,nDum,ibeg,iend,jbeg,jend,kbeg,kend, &
                            iCOff,ijCOff,nDel,idBeg,idEnd,fact1,fact2,fbVar, &
                            wrkBar )

! finally, integrate over K-direction

  CALL TURB_FloLesUniFiltCCK( global,nDum,ibeg,iend,jbeg,jend,kbeg,kend, &
                           iCOff,ijCOff,nDel,idBeg,idEnd,fact1,fact2,wrkBar, &
                           fbVar )

! deallocate temporary arrays

  DEALLOCATE( wrkBar )

! finalize --------------------------------------------------------------------

  CALL DeregisterFunction( global )

END SUBROUTINE TURB_FloLesUniFiltCC

!******************************************************************************
!
! RCS Revision history:
!
! $Log: TURB_floLesUniFiltCC.F90,v $
! Revision 1.5  2008/12/06 08:44:43  mtcampbe
! Updated license.
!
! Revision 1.4  2008/11/19 22:17:55  mtcampbe
! Added Illinois Open Source License/Copyright
!
! Revision 1.3  2004/06/03 02:12:41  wasistho
! expand CC-filtering to all dummy layers
!
! Revision 1.2  2004/03/12 02:55:36  wasistho
! changed rocturb routine names
!
! Revision 1.1  2004/03/08 23:35:45  wasistho
! changed turb nomenclature
!
! Revision 1.2  2003/05/15 02:57:06  jblazek
! Inlined index function.
!
! Revision 1.1  2002/10/14 23:55:30  wasistho
! Install Rocturb
!
!
!******************************************************************************







