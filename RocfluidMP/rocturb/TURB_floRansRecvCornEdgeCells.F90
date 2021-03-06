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
! Purpose: receives values for edge and corner cells from an adjacent
!          region.
!
! Description: this is for the case if the other region is located
!              on a different processor.
!
! Input: regions = data of all regions
!        iReg    = current region.
!
! Output: new values of RaNS variables.
!
! Notes: none.
!
!******************************************************************************
!
! $Id: TURB_floRansRecvCornEdgeCells.F90,v 1.6 2009/08/26 12:28:53 mtcampbe Exp $
!
! Copyright: (c) 2001 by the University of Illinois
!
!******************************************************************************

SUBROUTINE TURB_FloRansRecvCornEdgeCells( regions,iReg )

  USE ModDataTypes
  USE ModGlobal, ONLY     : t_global
  USE ModDataStruct, ONLY : t_region, t_level, t_dCellTransf
  USE ModInterfaces, ONLY : RFLO_GetCellOffset, RFLO_GetEdgeCellsIndices, &
                            RFLO_GetCornerCellsIndices
  USE ModError
  USE ModMPI
  USE ModParameters
  USE TURB_ModParameters
  IMPLICIT NONE

#include "Indexing.h"

! ... parameters
  TYPE(t_region), POINTER :: regions(:)

  INTEGER :: iReg

! ... loop variables
  INTEGER :: ir, iedge, icorner, i, j, k, l, ijk

! ... local variables
#ifdef MPI
  INTEGER :: status(MPI_STATUS_SIZE)
#endif
  INTEGER :: iLev, nCv, iRegSrc, ibuff, nDim, source, tag
  INTEGER :: ibeg, iend, jbeg, jend, kbeg, kend, iCOff, ijCOff, ijkC

  REAL(RFREAL), POINTER :: tcv(:,:)

  TYPE(t_global), POINTER      :: global
  TYPE(t_level), POINTER       :: level
  TYPE(t_dCellTransf), POINTER :: rcvTurbEcCell

!******************************************************************************

  global => regions(iReg)%global

  CALL RegisterFunction( global,'TURB_FloRansRecvCornEdgeCells',&
  'TURB_floRansRecvCornEdgeCells.F90' )

  iLev  =  regions(iReg)%currLevel
  nCv   =  regions(iReg)%turbInput%nCv

  level => regions(iReg)%levels(iLev)
  tcv   => level%turb%cv

  CALL RFLO_GetCellOffset( regions(iReg),iLev,iCOff,ijCOff )

! copy data from buffer to dummy cells

  DO ir=1,global%nRegions
    IF (regions(ir)%procid /= global%myProcid) THEN
    IF (level%rcvTurbEcCells(ir)%nCells > 0) THEN

      rcvTurbEcCell => level%rcvTurbEcCells(ir)
      nDim          =  rcvTurbEcCell%nCells
      ibuff         =  0

#ifdef MPI
      source = regions(ir)%procid
      tag    = regions(iReg)%localNumber + TURB_TAG_SHIFT
      IF(tag .GT. global%mpiTagMax) tag = MOD(tag,global%mpiTagMax)
      CALL MPI_Recv( rcvTurbEcCell%buff,nCv*nDim,MPI_RFREAL, &
                     source,tag,global%mpiComm,status,global%mpierr )
      IF (global%mpierr /= 0) CALL ErrorStop( global,ERR_MPI_TROUBLE,__LINE__ )
#endif

! --- edges

      DO iedge=1,12
        IF (level%edgeCells(iedge)%interact.eqv..true.) THEN
          CALL RFLO_GetEdgeCellsIndices( regions(iReg),iLev,iedge, &
                                         ibeg,iend,jbeg,jend,kbeg,kend )

          ijk = 0
          DO k=kbeg,kend
            DO j=jbeg,jend
              DO i=ibeg,iend
                ijk     = ijk + 1
                ijkC    = IndIJK(i,j,k,iCOff,ijCOff)
                iRegSrc = level%edgeCells(iedge)%cells(ijk)%srcRegion
                IF (iRegSrc == ir) THEN
                  ibuff = ibuff + 1
                  IF (level%edgeCells(iedge)%cells(ijk)%rotate.eqv..true.) THEN
                    ! rotational periodicity
                  ELSE
                    DO l=1,nCv
                      tcv(l,ijkC) = rcvTurbEcCell%buff(ibuff+(l-1)*nDim)
                    ENDDO
                  ENDIF
                ENDIF
              ENDDO
            ENDDO
          ENDDO

        ENDIF  ! interact
      ENDDO    ! iedge

! --- corners (currently not participating)

!      DO icorner=1,8
!        IF (level%cornerCells(icorner)%interact) THEN
!          CALL RFLO_GetCornerCellsIndices( regions(iReg),iLev,icorner, &
!                                           ibeg,iend,jbeg,jend,kbeg,kend )

!          ijk = 0
!          DO k=kbeg,kend
!            DO j=jbeg,jend
!              DO i=ibeg,iend
!                ijk     = ijk + 1
!                ijkC    = IndIJK(i,j,k,iCOff,ijCOff)
!                iRegSrc = level%cornerCells(icorner)%cells(ijk)%srcRegion
!                IF (iRegSrc == ir) THEN
!                  ibuff = ibuff + 1
!                  IF (level%cornerCells(icorner)%cells(ijk)%rotate) THEN
!                    ! rotational periodicity
!                  ELSE
!                    DO l=1,nCv
!                      tcv(l,ijkC) = rcvTurbEcCell%buff(ibuff+(l-1)*nDim)
!                    ENDDO
!                  ENDIF
!                ENDIF
!              ENDDO
!            ENDDO
!          ENDDO

!        ENDIF  ! interact
!      ENDDO    ! icorner

    ENDIF      ! some cells to receive
    ENDIF      ! not my processor
  ENDDO        ! ir

! finalize

  CALL DeregisterFunction( global )

END SUBROUTINE TURB_FloRansRecvCornEdgeCells

!******************************************************************************
!
! RCS Revision history:
!
! $Log: TURB_floRansRecvCornEdgeCells.F90,v $
! Revision 1.6  2009/08/26 12:28:53  mtcampbe
! Ported to Hera.   Fixed logical expression syntax errors.  Replaced all
! IF (logical_variable)  with IF (logical_variable .eqv. .true.) as
! consistent with the specification.  Also changed: IF( ASSOCIATED(expr) )
! to IF ( ASSOCIATED(expr) .eqv. .true. ).   Intel compilers produce code
! which silently fails for some mal-formed expressions, so these changes
! are a net which should ensure that they are evaluated as intended.
!
! Revision 1.5  2009/04/07 15:00:28  mtcampbe
! Fixed possible tag errors.
!
! Revision 1.4  2008/12/06 08:44:44  mtcampbe
! Updated license.
!
! Revision 1.3  2008/11/19 22:17:56  mtcampbe
! Added Illinois Open Source License/Copyright
!
! Revision 1.2  2004/03/12 02:55:36  wasistho
! changed rocturb routine names
!
! Revision 1.1  2004/03/08 23:35:45  wasistho
! changed turb nomenclature
!
! Revision 1.2  2004/02/18 22:51:32  wasistho
! added TURB_TAG_SHIFT in mpi_recv tag
!
! Revision 1.1  2004/01/23 00:39:06  wasistho
! added communication routines for RaNS edge/corners
!
!
!******************************************************************************







