!================================================================================
!Name        : module_GAM
!Version     : Beta 1.0
!Authors     : Alfredo Blanco Serrano <alfredoblancoserrano@gmail.com>
!              Alfonso Allen-Perkins <alfonso.allen.perkins@gmail.com>
!              Roberto F. S. Andrade <randrade@ufba.br>
!================================================================================
!About this module: This module contains all the necessary subroutines
!                   for the computation of the mean square distance (MSD) as
!                   described in the Main_GAM.
!
! Initialization    : This code allows the assignment of values to variables that
!                     do not depend on main loop.
! ST                : The stochastic transition matrix is constructed. For more
!                     details see Equation (5) of the manuscript.
! MELLI             : Mellin transformed d-path adjacency matrix(TM).
! Num_Deri          : Calculation of the numerical derivative.
! TH                : Calculation of the neighborhood matrix and the diameter for
!                     a TH of size N.
! Heaviside         : Heaviside step function, or the unit step function.
! TN                : Calculation of the neighborhood matrix and the diameter for
!                     a TN of size.
! Line_TN & dis_TN  : These codes are used by the TN algorithm to estimate the
!                     neighborhood matrix.
! Data_Reading      : Subroutine that reads the initial data from the
! write_data        : Writing the results obtained.
!================================================================================
MODULE module_GAM
!==========================universal variables====================================
INTEGER,PARAMETER :: sp=4,dp=8

REAL(dp)   ,DIMENSION(:,:),ALLOCATABLE :: TM
REAL(dp)   ,DIMENSION(:,:),ALLOCATABLE :: S
REAL(dp)   ,DIMENSION(:,:),ALLOCATABLE :: PTR
REAL(dp)   ,DIMENSION(:,:),ALLOCATABLE :: MSDT
REAL(dp)   ,DIMENSION(:)  ,ALLOCATABLE :: Deri
REAL(dp)   ,DIMENSION(:)  ,ALLOCATABLE :: Alp
INTEGER(sp),DIMENSION(:,:),ALLOCATABLE :: Adja
INTEGER(sp),DIMENSION(:,:),ALLOCATABLE :: MC

REAL(dp)      :: flag_alpha
INTEGER(sp)   :: N,Nas,tf,dmax,ALLOCATESTATUS,flag_T
CHARACTER(30) :: data_alpha,input,result

!================================================================================
CONTAINS
!================================================================================
SUBROUTINE Initialization
  IMPLICIT NONE
  INTEGER(sp) :: i
!========================Initialization of required variables=====================
  ALLOCATE(ADJA(N,N), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0)STOP "***NOT ENOUGH MEMORY ***"
  ALLOCATE(S(N,N), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0)STOP "***NOT ENOUGH MEMORY ***"
  ALLOCATE(TM(N,N), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0)STOP "***NOT ENOUGH MEMORY ***"
  ALLOCATE(PTR(N,N), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0)STOP "***NOT ENOUGH MEMORY ***"
  ALLOCATE(MSDT(tf,2), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0)STOP "***NOT ENOUGH MEMORY ***"
  ALLOCATE(MC(N,N), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0)STOP "***NOT ENOUGH MEMORY ***"
  ALLOCATE(ALP(tf), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0)STOP "***NOT ENOUGH MEMORY ***"
  ALLOCATE(deri(tf), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0)STOP "***NOT ENOUGH MEMORY ***"
  deri=0.d0;alp=0.d0
!========================Reading alpha data=======================================
  IF(flag_alpha .LT. 0)THEN
      OPEN(UNIT=10,FILE=data_alpha,STATUS='unknown')
      DO i=1,6
        READ(10,*)
      END DO
      DO i=1,Nas
        READ(10,*)alp(i)
      END DO
      CLOSE(10)
  ELSE
      alp(1:tf)=flag_alpha
  END IF
!========================Initialization of required variables=====================

  IF(flag_T .GT. 0)THEN
    CALL TH(N,MC,ADJA,dmax)
  ELSE
    CALL TN(N,MC,ADJA,dmax)
  END IF
  PTR=REAL(ADJA)

  DO i=2,tf
    MSDT(i,1)=REAL(i)
  END DO
  MSDT(1,1)=1.d0;MSDT(1,2)=1.d0

  RETURN
END SUBROUTINE Initialization
!================================================================================
SUBROUTINE ST(TM,S)
!======================= stochastic transition matrix============================
  IMPLICIT NONE
  REAL(dp), DIMENSION(:,:), INTENT(IN)  :: TM
  REAL(dp), DIMENSION(:,:), INTENT(OUT) :: S

  REAL(dP), DIMENSION(:,:), ALLOCATABLE :: B
  REAL(dp)    :: k
  INTEGER(sp) :: i

  ALLOCATE(B(n,n), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"

  B=0.d0;S=0.d0

  DO i=1,n
    k=SUM(TM(i,1:n))
    S(i,1:n)=TM(i,1:n)/k
  END DO

  DO i=1,n
    B(1:n,i)=S(i,1:n)
  END DO
  S(1:n,1:n)=B(1:n,1:n)

  DEALLOCATE(B, STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"
  RETURN
END SUBROUTINE ST
!================================================================================
!================================================================================
SUBROUTINE MELLI(A,MC,dmax,Alpha,t,TM)
!================Mellin transformed d−path adjacency matrix======================
  IMPLICIT NONE
  INTEGER(sp), DIMENSION(:,:), INTENT(IN)  :: A
  INTEGER(sp), DIMENSION(:,:), INTENT(IN)  :: MC
  REAL(dp),    DIMENSION(:),   INTENT(IN)  :: Alpha
  INTEGER(sp),                 INTENT(IN)  :: dmax,t
  REAL(dp),    DIMENSION(:,:), INTENT(OUT) :: TM


  REAL(dp),ALLOCATABLE,DIMENSION(:,:) :: B,DUMMY
  REAL(dp)    :: d
  INTEGER(sp) :: Amostra,i,j,k

  ALLOCATE(B(n,n), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"
  ALLOCATE(DUMMY(n,n), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"

  B(1:n,1:n)=REAL(A(1:n,1:n))
  DO i=2,dmax
    DUMMY(1:n,1:n)=0.d0
    DO j=1,n
      DO k=1,n
        Amostra=MC(j,k)
        IF(Amostra .EQ. i )DUMMY(j,k)=1.d0
      END DO
    END DO
    d=1.d0/REAL(i)**(Alpha(t))

    B(1:n,1:n)=B(1:n,1:n)+d*DUMMY(1:n,1:n)
  END DO

  TM(1:n,1:n)=B(1:n,1:n)
  DEALLOCATE(B, STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"
  DEALLOCATE(DUMMY, STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"
  RETURN
END SUBROUTINE MELLI
!=================================================================================
SUBROUTINE Num_Deri(A,B)
!===========================Log10 Numerical Derivative============================
  IMPLICIT NONE
  REAL(dp),DIMENSION(:,:),INTENT(IN)  :: A
  REAL(dp),DIMENSION(:),  INTENT(OUT) :: B

  REAL(dp)    :: yo,y1,xo,x1,m,d,c
  INTEGER(sp) :: i

  DO i=1,tf-1
    yo=dlog10(A(i,2))
    y1=dlog10(A(i+1,2))

    xo=dlog10(A(i,1))
    x1=dlog10(A(i+1,1))

    d=(y1-yo);c=(x1-xo)
    m=d/c
    B(i)=m
  END DO
  B(tf)=B(tf-1)
  RETURN
END SUBROUTINE Num_Deri
!=================================================================================
SUBROUTINE TH(n,MC,A,dmax)
!===============Adjacency and neighborhood matrix of the TH=======================
  IMPLICIT NONE

  INTEGER(sp), DIMENSION(:,:),INTENT(OUT) :: A
  INTEGER(sp), DIMENSION(:,:),INTENT(OUT) :: MC
  INTEGER(sp), INTENT(IN)  :: n
  INTEGER(sp), INTENT(OUT) :: dmax

  INTEGER(sp), DIMENSION(:,:), ALLOCATABLE :: B
  INTEGER(sp), DIMENSION(:,:), ALLOCATABLE :: E
  INTEGER(sp), DIMENSION(:),   ALLOCATABLE :: dist

  REAL(sp) :: x,jj1
  INTEGER(SP) :: JO2,JO,j,h,h2,sj,xj,i,d1,d2
  INTEGER(SP) :: JJ0,X1,nq,INSQRT,inN

  ALLOCATE(B(n,n), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"
  ALLOCATE(E(n,n), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"
  ALLOCATE(dist(n), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"
  inN=N;nq=inN;B=0;dist=0;E=0;d2=1
  INSQRT=INT(SQRT(REAL(nq)))

  DO j=1,nq

    JJ0=j-((NQ+3)/2)
    jj1=((Real(nq)+2.0)/2.0)-real(j)
    jj1=sign(1.0,jj1)
    CALL Heaviside(JJ0,X1)
    xj=(nq+2)*X1+(j)*INT(jj1)-1

    sj=inN-j+1
    JO=MOD(xj+1,INSQRT)
    JO2=JO-NINT(((REAL(INSQRT)+3.0)/2.0))
    CALL Heaviside(-JO,H);CALL Heaviside(JO2,h2)

    x=(REAL(xj)/REAL(INSQRT))+((REAL(JO)-1.0)*((REAL(INSQRT)-1.0)/REAL(INSQRT)))

    dist(j)=(NINT(x)+2*H-2*h2*JO2)
  END DO

  DO i=1,nq
    DO j=i,nq
      B(i,j)=dist(j-i+1)
    END DO
  END DO

  DO i=1,nq
    E(i:nq,i)=B(i,i:nq)
  END DO
  E=B+E
  B=0
  DO i=1,nq
    DO j=1,nq
      d1=E(i,j)
      IF(d1 .EQ. 1)B(i,j)=1
      IF(d1 .GT. d2)d2=d1
    END DO
  END DO
  A=B;MC=E;dmax=d2
  DEALLOCATE(B, STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"
  DEALLOCATE(E, STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"
  DEALLOCATE(dist, STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"
  RETURN
END SUBROUTINE TH
!================================================================================
SUBROUTINE Heaviside(x,y)
!===============================heaviside function===============================
  IMPLICIT NONE
  INTEGER(sp),INTENT(IN)  :: x
  INTEGER(sp),INTENT(OUT) :: y
  y=NINT(0.5*(sign(1,x)+1))
  return
END SUBROUTINE Heaviside
!================================================================================
SUBROUTINE TN(n,A,C,dmax)
!===============Adjacency and neighborhood matrix of the TN=======================
  IMPLICIT NONE
  INTEGER(sp), DIMENSION(:,:),INTENT(OUT) :: A
  INTEGER(sp), DIMENSION(:,:),INTENT(OUT) :: c
  INTEGER(sp), INTENT(IN)  :: n
  INTEGER(sp), INTENT(OUT) :: dmax

  INTEGER(sp), DIMENSION(:,:), ALLOCATABLE :: B
  INTEGER(sp), DIMENSION(:,:), ALLOCATABLE :: E

  INTEGER(sp) :: i,j,INn,d,d1

  INn=INT(SQRT(REAL(n)))

  ALLOCATE(B(n,n), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"
  ALLOCATE(E(n,n), STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"

  B=0;E=0;d1=1
  DO i=1,n
    DO j=1,n
      CALL Line_TN(i,j,n,d)
      B(i,j)=d
      IF(d .GT. d1)d1=d
    END DO
  END DO

  DO i=1,n
    DO j=1,n
      d=B(i,j)
      IF (d .EQ. 1)E(i,j)=1
    END DO
  END DO

  A=B;C=E;dmax=d1
  DEALLOCATE(B, STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"
  DEALLOCATE(E, STAT=ALLOCATESTATUS)
  IF(ALLOCATESTATUS .NE. 0 )STOP "*** NOT ENOUGH MEMORY ***"
  RETURN
END SUBROUTINE TN
!================================================================================
SUBROUTINE Line_TN(a,b,n,D)
!========Calculation of the first row of the neighborhood matrix=================
  IMPLICIT NONE
  INTEGER(sp), INTENT(IN) :: a,b
  INTEGER(sp), INTENT(IN) :: n
  INTEGER(sp),INTENT(OUT) :: D

  INTEGER(sp) :: x1,x2,xmax1,xmin1,xmax2,xmin2
  INTEGER(sp) :: a1,i,j1,j2,a2
  INTEGER(sp) :: D1,D2,Rn


  Rn=INT(SQRT(REAL(n)))
  x1=CEILING(REAL(a)/REAL(Rn));x2=CEILING(REAL(b)/REAL(Rn))
  xmax1=x1*Rn;xmin1=Rn*(x1-1)+1
  xmax2=x2*Rn;xmin2=Rn*(x2-1)+1

  j1=xmin1
  j2=xmin2

  DO i=1,Rn
    IF(a .EQ. j1)THEN
      a1=i
      EXIT
    END IF
    j1=xmin1+i
  END DO

  DO i=1,Rn
    IF(b .EQ. j2)THEN
      a2=i
      EXIT
    END IF
    j2=xmin2+i
  END DO
  CALL Dis_TN(a1,a2,n,D1)
  CALL Dis_TN(x1,x2,n,D2)
  D=D1+D2
  RETURN
END SUBROUTINE Line_TN
!================================================================================
SUBROUTINE Dis_TN(a,b,n,D)
!=====================Distance between two nodes in the TN=======================
IMPLICIT NONE
INTEGER(sp), INTENT(IN) :: a,b
INTEGER(sp), INTENT(IN) :: n
INTEGER(sp),INTENT(OUT) :: D

REAL(sp) :: D1
INTEGER(sp) :: fun,x1,Rn

Rn=INT(SQRT(REAL(n)))

x1=abs(a-b)
D1=(REAL(Rn)/2)
IF(x1 .LT. D1)THEN
  fun=x1
ELSE
  fun=Rn-x1
END IF

D=fun
RETURN
END SUBROUTINE Dis_TN
!================================================================================
SUBROUTINE Data_Reading
!================================================================================
  IMPLICIT NONE
  input="in_GAM_data.dat"
  OPEN(UNIT=10,FILE=input,STATUS='unknown')
  READ(10,*)N,NAS,tf
  READ(10,*)flag_T,flag_alpha
  READ(10,*)data_alpha
  READ(10,*)result
  CLOSE(10)
  RETURN
END SUBROUTINE Data_Reading
!================================================================================
SUBROUTINE Write_Data(secs)
!================================================================================
  IMPLICIT NONE
  REAL(sp), INTENT(IN) :: secs
  INTEGER(sp) :: i

  OPEN(UNIT=10,FILE=result,STATUS='unknown')
  WRITE(10,*)'#==================================================#'
  WRITE(10,502) "#",'time= ',secs, '[s]','input= ',input,'#'
  WRITE(10,*)'#==================================================#'
  WRITE(10,*)
  WRITE(10,*)"#",'  Log10(t)','       Log10(MSD)', '      Derivative'
  DO i=1,tf
   WRITE(10,501) dlog10(MSDT(i,1)),dlog10(MSDT(i,2)),deri(i)
  END DO
  CLOSE(10)
  501 FORMAT(2x,f12.10,4x,f12.10,4x,f12.10)
  502 FORMAT(1x,a,a6,f11.7,a3,2x,a7,a20,1x,a)
  RETURN
END SUBROUTINE Write_Data
END MODULE module_GAM
!================================================================================
