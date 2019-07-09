        IDENTIFICATION DIVISION.                                                  000000 
        PROGRAM-ID. ZSCLAWBACK.                                                   151030 
       *                                                                          950209 
       * Copyright 1986-2019, Computer Sciences Corporation.                      190131 
       *           COMMISSION CLAWBACK SUBROUTINE                                 181017 
       *                                                                          950209 
       *REMARKS.                                                                  140603 
       *                                                                          000801 
       ***********************************************************************    950428 
       *           AMENDMENT  HISTORY                                        *    181010 
       ***********************************************************************    950428 
       * DATE.... VSN/MOD  WORK UNIT    BY....                               *    950428 
       *                                                                     *    950428 
       * 30/10/15  01/01   ATHA39       Androni Katerina                     *    151223 
       *           INITIAL VERSION                                           *    151030 
       *                                                                     *    151030 
       * 05/02/16  01/01   ATHA43       Androni Katerina                     *    160324 
       *           PHASE II- MCPPI  PARTIAL SURRENDER                        *    160205 
       *                                                                     *    160205 
       * 04/04/16  01/01   ATHA67       Androni Katerina                     *    160607 
       *           CLAWBACK CHANGES/ PARTIAL SURRENDER                       *    160404 
       *                                                                     *    160404 
       * 08/02/17  01/01   ATHB37       Androni Katerina                     *    170208 
       *           PREMIUM DECREASE CLAWBACK                                 *    170208 
       *                                                                     *    170208 
       * 10/03/17  01/01   ATHB45       Androni Katerina                     *    170310 
       *           CHANGES FOR THE NEW LOYALTY BONUS                         *    170823 
       *                                                                     *    170310 
       * 23/08/17  01/01   ATHB87       Androni Katerina                     *    170823 
       *           CHANGES FOR NEW UL REGULAR. DO NOT WRITE ACCOUNT 52       *    170823 
       *           FOR TOPUP COVERAGES.                                           170823 
       *                                                                     *    170823 
       * 08/03/18  01/01   ATHC41       Androni Katerina                     *    180308 
       *           MG1 PARTIAL SURRENDER CHANGES                             *    180308 
       *                                                                     *    180308 
       * 28/09/18  01/01   TSTDBG       Mitraina Eyaggelia                   *    180928 
       *           DEBUG                                                     *    180928 
       *                                                                     *    180928 
       * 12/10/18  01/01   ATHD11       Mitraina Eyaggelia                   *    181012 
       *           US515- Add Clawback Functionality for UL                  *    181012 
       *                  Method SURRF must write in ZTUD also.              *    181012 
       *                                                                     *    181012 
       * 31/01/19  01/01   TSTDBG       Zois George                          *    190131 
       *           DEBUG                                                     *    190131 
       *                                                                     *    190131 
       **DD/MM/YY*************************************************************    190131 
       *                                                                          000000 
        ENVIRONMENT DIVISION.                                                     151030 
        CONFIGURATION SECTION.                                                    151030 
        SOURCE-COMPUTER.                                IBM-AS400.                151030 
        OBJECT-COMPUTER.                                IBM-AS400.                151030 
                                                                                  151030 
        INPUT-OUTPUT SECTION.                                                     151030 
        FILE-CONTROL.                                                             151030 
       /                                                                          151030 
        DATA DIVISION.                                                            151030 
        FILE SECTION.                                                             151030 
       /                                                                          151030 
        WORKING-STORAGE SECTION.                                                  151030 
        01  WSAA-SUBR                      PIC  X(10) VALUE 'ZSCLAWBACK'.         151030 
        01  WSAA-VERSION                   PIC  X(02) VALUE '01'.                 151030 
                                                                                  151030 
        01  FORMATS.                                                              151030 
            03  ITEMREC                    PIC  X(10) VALUE 'ITEMREC'.            151030 
            03  ITDMREC                    PIC  X(10) VALUE 'ITEMREC'.            151030 
            03  CHDRMJAREC                 PIC  X(10) VALUE 'CHDRMJAREC'.         151103 
            03  ACMVBK3REC                 PIC  X(10) VALUE 'ACMVBK3REC'.         151103 
            03  ACMVREVREC                 PIC  X(10) VALUE 'ACMVREVREC'.         151109 
            03  ZTUDREC                    PIC  X(10) VALUE 'ZTUDREC'.            151030 
            03  ZTUHREC                    PIC  X(10) VALUE 'ZTUHREC'.            151110 
            03  ZTUHTRNREC                 PIC  X(10) VALUE 'ZTUHTRNREC'.         151110 
            03  ZCHDREC                    PIC  X(10) VALUE 'ZCHDREC'.            151104 
            03  AGCMBCRREC                 PIC  X(10) VALUE 'AGCMBCRREC'.         151104 
            03  AGNTREC                    PIC  X(10) VALUE 'AGNTREC'.            151109 
            03  ZCHAREC                    PIC  X(10) VALUE 'ZCHAREC'.            151110 
            03  ZCLBREC                    PIC  X(10) VALUE 'ZCLBREC'.            151112 
            03  ZCLBCOVREC                 PIC  X(10) VALUE 'ZCLBCOVREC'.<ATHA67> 160404 
            03  AGLFREC                    PIC  X(10) VALUE 'AGLFREC'.            151113 
            03  PTRNREVREC                 PIC  X(10) VALUE 'PTRNREVREC'.         151114 
            03  COVRAFIREC                 PIC  X(10) VALUE 'COVRAFIREC'.<ATHB37> 170210 
            03  CHDRAFIREC                 PIC  X(10) VALUE 'CHDRAFIREC'.<ATHB37> 170210 
            03  ZCOVCRTREC                 PIC  X(10) VALUE 'ZCOVCRTREC'.<ATHB45> 170310 
                                                                                  151030 
        01  WSAA-ITDMKEY.                                                         151030 
            COPY ITDMKEY.                                                         151030 
                                                                                  151030 
        01  TABLES.                                                               151030 
            03  T8Z82                      PIC  X(06) VALUE 'T8Z82'.              151030 
            03  T5645                      PIC  X(06) VALUE 'T5645'.              151030 
            03  T7Z11                      PIC  X(06) VALUE 'T7Z11'.     <ATHB37> 170214 
            03  T5Z01                      PIC  X(06) VALUE 'T5Z01'.     <ATHB37> 170214 
            03  T5694                      PIC  X(06) VALUE 'T5694'.     <ATHB37> 170302 
            03  T5673                      PIC  X(06) VALUE 'T5673'.     <ATHB45> 170313 
            03  T5687                      PIC  X(06) VALUE 'T5687'.     <ATHB45> 170313 
            03  T8Z05                      PIC  X(06) VALUE 'T8Z05'.     <ATHD11> 181019 
                                                                                  151109 
        01  ERRORS.                                                               151109 
            03  H028                    PIC X(4)  VALUE 'H028'.                   151109 
            03  H791                    PIC X(4)  VALUE 'H791'.                   151113 
                                                                                  151030 
        01  WSAA-VARIABLES.                                                       151030 
            03  WSAA-NEXT-ANNI-DATE     PIC 9(08) COMP-3 VALUE ZERO.              151109 
            03  WSVA-OCCDATE            PIC 9(08) COMP-3 VALUE ZERO.              151030 
            03  WSVA-HOLE-DATE.                                                   151030 
                05  WSVA-YEARS          PIC S9(06)  VALUE ZERO.                   151030 
                05  WSVA-REST           PIC  9(05)  VALUE ZERO.                   151030 
            03  WSAA-INSTPREM           PIC S9(11)V9(02) COMP-3.                  151030 
            03  WSAA-TOT-INSTPREM       PIC S9(11)V9(02) COMP-3.                  151030 
            03  WSAA-VAR-IDX            PIC S9(05)V9(02).                         151030 
            03  WSAA-TEMP-VAR-IDX       PIC S9(12)V9(06).                         151030 
            03  WSAA-IND1               PIC  9(03).                               151109 
            03  WSAA-IND2               PIC  9(03).                      <ATHB37> 170208 
            03  WSAA-INDEX              PIC  9(03).                               151103 
            03  WSAA-ARRAY-INDEX        PIC  9(03).                      <ATHB37> 170214 
            03  WSAA-ARRAY-INDEX2       PIC  9(03).                      <ATHB37> 170214 
            03  IX-SA                   PIC  9(02).                               151111 
            03  WSAA-TERM               PIC  9(02).                               151103 
            03  WSAA-TERMW              PIC  9(02).                      <ATHB37> 170214 
            03  WSAA-CESS-TERM          PIC  9(02).                      <ATHB37> 170214 
            03  WSAA-FROM-DATE          PIC  9(08).                               151109 
            03  WSAA-T8Z82              PIC S9(03)V99  VALUE ZERO.                151103 
            03  WSAA-T7Z11              PIC S9(03)V9(04) VALUE ZERO.     <ATHB37> 170214 
            03  WSAA-T5694              PIC S9(03)V9(04) VALUE ZERO.     <ATHB37> 170302 
            03  WSAA-LAST-RLDGACCT          PIC X(16).                            151216 
            03  WSAA-USED-RLDGACCT          PIC X(16).                            151216 
            03  WSAA-ACMV-RLDGACCT.                                               151216 
                05  WSAA-ACMV-CHDRNUM       PIC X(08).                            151030 
                05  WSAA-ACMV-LIFE          PIC X(02).                            151030 
                05  WSAA-ACMV-COVERAGE      PIC X(02).                            151030 
                05  WSAA-ACMV-RIDER         PIC X(02).                            151030 
                05  WSAA-ACMV-PLAN-SUFF     PIC X(02).                            151030 
            03  WSAA-PAID-PREM          PIC S9(11)V9(02) COMP-3.                  151109 
            03  WSAA-PAID-PREM-CLAWB    PIC S9(11)V9(02) COMP-3.                  151109 
            03  WSAA-PAID-COMM          PIC S9(11)V9(02) COMP-3.                  151109 
            03  WSAA-PAID-COMM-CLAWB    PIC S9(11)V9(02) COMP-3.                  151109 
            03  WSAA-PAID-OVRCOM        PIC S9(11)V9(02) COMP-3.                  151109 
            03  WSAA-PAID-OVRCOM-CLAWB  PIC S9(11)V9(02) COMP-3.                  151109 
            03  WSAA-TOT-CLAWB-TOPUP    PIC S9(11)V9(02) COMP-3.                  151109 
            03  WSAA-TOT-CLAWB-NET      PIC S9(11)V9(02) COMP-3.                  151116 
            03  WSAA-TOT-CLAWB-OVRAMT   PIC S9(11)V9(02) COMP-3.                  151116 
            03  WSAA-CLAWBACK-TOPUP     PIC S9(11)V9(02) COMP-3.                  151109 
            03  WSAA-CLAWBACK-NET       PIC S9(11)V9(02) COMP-3.                  151110 
            03  WSAA-CLAWBACK-OVRAMT    PIC S9(11)V9(02) COMP-3.                  151118 
            03  WSAA-OVRAMT-TOPUP       PIC S9(11)V9(02) COMP-3.                  151118 
            03  WSAA-PRV-CLAW-PREM      PIC S9(11)V9(02) COMP-3.         <ATHA67> 160404 
            03  WSAA-PRV-CLAW-COMM      PIC S9(11)V9(02) COMP-3.         <ATHA67> 160404 
            03  WSAA-PRV-CLAW-OVRC      PIC S9(11)V9(02) COMP-3.         <ATHA67> 160404 
            03  WSAA-CLAW-PREM-REMN     PIC S9(11)V9(02) COMP-3.         <ATHA67> 160404 
            03  WSAA-CLAW-COMM-REMN     PIC S9(11)V9(02) COMP-3.         <ATHA67> 160404 
            03  WSAA-CLAW-OVRC-REMN     PIC S9(11)V9(02) COMP-3.         <ATHA67> 160404 
            03  WSAA-CRCODE                PIC  X(01).                            151103 
            03  WSAA-AGNTNUM               PIC  X(08).                            151109 
            03  WSAA-AGNTNUM-INIT          PIC  X(08).                            151123 
            03  WSAA-ZCHA-CLNTNUM          PIC  X(08).                            151110 
            03  WSAA-ZCHD-CLNTNUM          PIC  X(08).                            151110 
            03  WSAA-AGCM-CLNTNUM          PIC  X(08).                            151109 
            03  WSAA-ZTUD-ARRAY-CNT        PIC  9(03).                            151109 
            03  WSAA-ZTUD-ARRAY.                                                  151109 
                05  WSAA-ZTUD-RECODE       PIC  X(02) OCCURS 999.                 151109 
                05  WSAA-ZTUD-EFFDATE      PIC  9(08) OCCURS 999.                 151109 
                05  WSAA-ZTUD-ZPREMAMT     PIC  9(13)V9(02) OCCURS 999.           151109 
                05  WSAA-ZTUD-ZCOMMAMT     PIC  9(13)V9(02) OCCURS 999.           151109 
                05  WSAA-ZTUD-NET          PIC  9(13)V9(02) OCCURS 999.           151109 
                05  WSAA-ZTUD-OVRAMT       PIC  9(13)V9(02) OCCURS 999.           151118 
                05  WSAA-ZTUD-JCOVCODE     PIC  X(05) OCCURS 999.                 151109 
                05  WSAA-ZTUD-LIFENUM      PIC  X(08) OCCURS 999.                 151109 
                05  WSAA-ZTUD-AGNTNUM      PIC  X(08) OCCURS 999.                 151109 
                05  WSAA-ZTUD-ZCLNTAGN     PIC  X(08) OCCURS 999.                 151109 
                05  WSAA-ZTUD-ZCLNTUNI     PIC  X(08) OCCURS 999.                 151109 
                05  WSAA-ZTUD-ZCLNTASS     PIC  X(08) OCCURS 999.                 151109 
                05  WSAA-ZTUD-ZCLNTAGY     PIC  X(08) OCCURS 999.                 151109 
            03  WSAA-ACMV-ARRAY-CNT        PIC  9(03).                   <ATHA67> 160513 
            03  WSAA-ACMV-ARRAY.                                         <ATHA67> 160513 
       **       05  WSAA-ACMV-RLDGACCT-W   PIC  X(16) OCCURS 999.                 151216 
                05  WSAA-ACMV-AGNTNUM      PIC  X(08) OCCURS 999.        <ATHA67> 160513 
                05  WSAA-ACMV-ZPREMAMT     PIC  9(13)V9(02) OCCURS 999.  <ATHA67> 160513 
                05  WSAA-ACMV-ZCOMMAMT     PIC  9(13)V9(02) OCCURS 999.  <ATHA67> 160513 
                05  WSAA-ACMV-OVRAMT       PIC  9(13)V9(02) OCCURS 999.  <ATHA67> 160513 
                05  WSAA-ACMV-CRTABLE      PIC  X(04) OCCURS 999.        <ATHA67> 160513 
            03  WSAA-YEARS-ARRAY.                                        <ATHB37> 170210 
                05  WSAA-FROM-DATE-W    PIC  9(08) OCCURS 25.            <ATHB37> 170208 
                05  WSAA-TO-DATE-W      PIC  9(08) OCCURS 25.            <ATHB37> 170208 
                05  WSAA-PAID-PREM-RP   PIC S9(13)V9(02) OCCURS 25.      <ATHB37> 170210 
                05  WSAA-PAID-OVRC-RP   PIC S9(13)V9(02) OCCURS 25.      <ATHB37> 170210 
                05  WSAA-PAID-COMM-RP   PIC S9(13)V9(02) OCCURS 25.      <ATHB37> 170210 
            03  WSAA-NEXT-ANNI-WRK      PIC 9(08) COMP-3 VALUE ZERO.     <ATHB37> 170208 
            03  WSAA-COUNT-YEAR         PIC 9(02).                       <ATHB37> 170208 
            03  WSAA-SYSR-PARAMS.                                                 151112 
                05  WSAA-SYSR-FORMAT    PIC  X(10).                               151110 
                05  WSAA-SYSR-CHDRNUM   PIC  X(08).                               151110 
            03  WSAA-CRTABLE            PIC  X(04).                               151111 
            03  WSAA-JRNSEQ             PIC S9(03) COMP-3.                        151112 
            03  WSAA-JPREMREG           PIC  X(09).                               151112 
            03  WSAA-BATCTRCDE          PIC  X(04).                               151114 
            03  WSAA-LAST-TRANNO        PIC  9(05).                               151216 
            03  WSAA-LAST-TRANNO-W      PIC  9(05).                               151216 
            03  WSAA-PARTS-PERC         PIC S9(03)V9(02) VALUE ZEROS.    <ATHA43> 160225 
            03  WSAA-PARTS-PERC-WRK     PIC S9(06)V9(04) VALUE ZEROS.    <ATHA43> 160324 
            03  WSAA-ZCLB-LIFE          PIC  X(02).                      <ATHA67> 160404 
            03  WSAA-ZCLB-COVERAGE      PIC  X(02).                      <ATHA67> 160404 
            03  WSAA-ZCLB-RIDER         PIC  X(02).                      <ATHA67> 160404 
            03  WSAA-ZCLB-RECODE        PIC  X(02).                      <ATHA67> 160406 
            03  WSAA-INIT-ANNPREM       PIC S9(11)V9(02) COMP-3.         <ATHB37> 170210 
            03  WSAA-DIFF-PREM          PIC S9(11)V9(02) COMP-3.         <ATHB37> 170213 
            03  WSAA-MIN-ANNPREM        PIC S9(11)V9(02) COMP-3.         <ATHB37> 170214 
            03  WSAA-COMM-WRK           PIC S9(11)V9(02) COMP-3.         <ATHB37> 170214 
            03  WSAA-OVRCOM-WRK         PIC S9(11)V9(02) COMP-3.         <ATHB37> 170214 
            03  WSAA-PREM-CLAWB         PIC S9(11)V9(02) COMP-3.         <ATHB37> 170215 
            03  WSAA-TU-LIFE            PIC X(02).                       <ATHB45> 170310 
            03  WSAA-TU-COVERAGE        PIC X(02).                       <ATHB45> 170310 
            03  WSAA-TU-RIDER           PIC X(02).                       <ATHB45> 170310 
            03  WSAA-TU-CRTABLE         PIC X(04).                       <ATHB45> 170310 
            03  WSAA-T5673-ITEM         PIC  X(08).                      <ATHB45> 181019 
            03  WSAA-READ-CRTABLE       PIC  X(04).                      <ATHB45> 181019 
            03  WSAA-COMM-RATE          PIC S9(03)V9(04) VALUE ZEROS.    <ATHD11> 181019 
                                                                                  151111 
        01  WSAA-RLDGACCT.                                                        151111 
            03  WSAA-RLDG-CHDRNUM       PIC X(08).                                151111 
            03  WSAA-RLDG-LIFE          PIC X(02).                                151111 
            03  WSAA-RLDG-COVERAGE      PIC X(02).                                151111 
            03  WSAA-RLDG-RIDER         PIC X(02).                                151111 
            03  WSAA-RLDG-PLAN-SUFFIX   PIC X(02).                                151111 
                                                                                  151111 
        01  WSAA-TRANREF.                                                         151111 
            03 WSAA-TRANCHDR            PIC X(26).                                151114 
            03 WSAA-EXT-IGNORE          PIC X(01).                                151111 
            03 WSAA-TRANAGNT            PIC X(03).                                151111 
                                                                                  151214 
        01  WSAA-TRANREF-TOP.                                                     151214 
            03 WSAA-TRANCHDR-TOP        PIC X(25).                                151214 
            03 WSAA-EXT-RECODE          PIC X(02).                                151214 
            03 WSAA-TRANAGNT-TOP        PIC X(03).                                151214 
                                                                                  151030 
        01  WSAA-OCCDATE                PIC 9(08).                                151030 
        01  WSAA-OCCDATE-A   REDEFINES WSAA-OCCDATE.                              151030 
       **   03  WSAA-OCC-YEAR           PIC 9(04).                                151103 
            03  WSAA-OCC-YEARMN         PIC 9(06).                                151103 
                05  WSAA-OCC-YEAR       PIC 9(04).                                151103 
                05  WSAA-OCC-MONTH      PIC 9(02).                                151103 
       **   03  WSAA-OCC-MONTH          PIC 9(02).                                151103 
            03  WSAA-OCC-DAY            PIC 9(02).                                151030 
                                                                                  151030 
        01  WSAA-BILLFREQ-VAR.                                                    151030 
            05  WSAA-BILLFREQ           PIC X(02).                                151030 
            05  FILLER REDEFINES WSAA-BILLFREQ.                                   151030 
                10  WSAA-BILLFREQ-NUM   PIC 9(02).                                151030 
        01  WSAA-FULL-DATE              PIC 9(08).                                151030 
        01  WSAA-FULL-DATE-B            PIC 9(08).                                151030 
        01  WSAA-FULL-DATE-C REDEFINES WSAA-FULL-DATE-B.                          151030 
       **   03  WSAA-YEAR               PIC 9(04).                       <ATHA37> 151030 
            03  WSAA-YEARMN             PIC 9(06).                       <ATHA37> 151030 
                05  WSAA-YEAR           PIC 9(04).                       <ATHA37> 151030 
                05  WSAA-MON            PIC 9(02).                       <ATHA37> 151030 
       **   03  WSAA-MON                PIC 9(02).                       <ATHA37> 151030 
            03  WSAA-DAY                PIC 9(02).                                151030 
                                                                         <ATHA37> 151030 
        01  WSAA-ACMV-DATE              PIC 9(06).                       <ATHA37> 151030 
        01  WSAA-ACMV-DATE-A REDEFINES WSAA-ACMV-DATE.                   <ATHA37> 151030 
            03  WSAA-ACMV-YEAR          PIC 9(04).                       <ATHA37> 151030 
            03  WSAA-ACMV-MONTH         PIC 9(02).                       <ATHA37> 151030 
                                                                                  151109 
        01  WSAA-ITEMITEM.                                                        151109 
       **   03  WSAA-ITEM-SRCEBUS       PIC X(02).                                151222 
            03  WSAA-ITEM-CNTTYPE       PIC X(03).                                151222 
            03  WSAA-ITEM-CRTABLE       PIC X(04).                                151109 
                                                                         <ATHB37> 170214 
        01  WSAA-ITEMITEM-IT.                                            <ATHB37> 170214 
            03  WSAA-METHOD-IT          PIC X(04).                       <ATHB37> 170214 
            03  WSAA-CRTABLE-IT         PIC X(03).                       <ATHB37> 170214 
                                                                                  151113 
        01  WSAA-T5645-SIZE             PIC 9(2) VALUE 30.                        151113 
        01  WSAA-T5645-OFFSET           PIC 9(2) VALUE 1.                         151113 
                                                                                  151113 
        01  WSAA-T5645-ARRAY.                                                     151113 
            03  WSAA-T5645-DATA OCCURS 30.                                        151113 
                05  WSAA-T5645-CNTTOT        PIC S9(02).                          151113 
                05  WSAA-T5645-GLMAP         PIC X(00014).                        151113 
                05  WSAA-T5645-SACSCODE      PIC X(00002).                        151113 
                05  WSAA-T5645-SACSTYPE      PIC X(00002).                        151113 
                05  WSAA-T5645-SIGN          PIC X(00001).                        151113 
                                                                                  151113 
        01  WSAA-T5645-SUB              PIC S9(5)    COMP-3.                      151113 
                                                                                  151030 
        01  WSCC-CONSTANTS.                                                       151030 
            03  WSCC-TXT-0                 PIC  X(01) VALUE '0'.                  151030 
            03  WSCC-TXT-1                 PIC  X(01) VALUE '1'.                  151030 
            03  WSCC-TXT-2                 PIC  X(01) VALUE '2'.                  151030 
            03  WSCC-NUM-1                 PIC  9(01) VALUE 1.                    151109 
            03  WSCC-01                    PIC  X(02) VALUE '01'.                 151030 
            03  WSCC-00                    PIC  X(02) VALUE '00'.                 151109 
            03  WSCC-LE                    PIC  X(02) VALUE 'LE'.                 151030 
            03  WSCC-BK                    PIC  X(02) VALUE 'BK'.                 151030 
            03  WSCC-PS                    PIC  X(02) VALUE 'PS'.                 151030 
            03  WSCC-LP                    PIC  X(02) VALUE 'LP'.                 151030 
            03  WSCC-YC                    PIC  X(02) VALUE 'YC'.                 151109 
            03  WSCC-LA                    PIC  X(02) VALUE 'LA'.                 151109 
            03  WSCC-CP                    PIC  X(02) VALUE 'CP'.                 151109 
            03  WSCC-AG                    PIC  X(02) VALUE 'AG'.                 151109 
            03  WSCC-OC                    PIC  X(02) VALUE 'OC'.                 151110 
            03  WSCC-CB                    PIC  X(02) VALUE 'CB'.                 151116 
            03  WSCC-SU                    PIC  X(02) VALUE 'SU'.                 151208 
            03  WSCC-CF                    PIC  X(02) VALUE 'CF'.                 151208 
            03  WSCC-T                     PIC  X(02) VALUE 'T '.                 151030 
            03  WSCC-P                     PIC  X(01) VALUE 'P'.                  151030 
            03  WSCC-NUM--1                PIC S9(01) VALUE -1.                   151030 
            03  WSCC-SURFS                 PIC  X(05) VALUE 'SURFS'.              151111 
            03  WSCC-SURCF                 PIC  X(05) VALUE 'SURCF'.              151116 
            03  WSCC-SURRF                 PIC  X(05) VALUE 'SURRF'.              151111 
            03  WSCC-SURTF                 PIC  X(05) VALUE 'SURTF'.              151111 
            03  WSCC-SURPS                 PIC  X(05) VALUE 'SURPS'.     <ATHA43> 160205 
            03  WSCC-SURPC                 PIC  X(05) VALUE 'SURPC'.     <ATHD11> 181016 
            03  WSCC-SURSP                 PIC  X(05) VALUE 'SURSP'.              151122 
            03  WSCC-SURGG                 PIC  X(05) VALUE 'SURGG'.     <ATHA67> 160407 
            03  WSCC-SURGP                 PIC  X(05) VALUE 'SURGP'.     <ATHC41> 180308 
            03  WSCC-CFIGG                 PIC  X(05) VALUE 'CFIGG'.     <ATHA67> 160413 
            03  WSCC-DECRP                 PIC  X(05) VALUE 'DECRP'.     <ATHB37> 170208 
            03  WSCC-EUR                   PIC  X(03) VALUE 'EUR'.                151030 
            03  WSCC-MINUS              PIC  X(01) VALUE '-'.            <ATHA37> 151030 
            03  WSCC-T679               PIC  X(04) VALUE 'T679'.         <ATHA37> 151030 
            03  WSCC-T607               PIC  X(04) VALUE 'T607'.         <ATHA37> 151030 
            03  WSCC-T656               PIC  X(04) VALUE 'T656'.         <ATHA37> 151030 
            03  WSCC-T646               PIC  X(04) VALUE 'T646'.         <ATHA37> 151030 
            03  WSCC-MAX-TRANNO         PIC  9(05) VALUE 99999.                   151109 
            03  WSCC-MAX-ARRAY          PIC  9(03) VALUE 999.                     151109 
            03 WSCC-NEXT                PIC X(04) VALUE 'NEXT'.                   151112 
            03 WSCC-REE1                PIC X(04) VALUE 'REE1'.          <ATHA43> 160323 
       /                                                                          151030 
        01  WS88-CONTROL-FLAGS.                                                   151030 
            03  WS88-MUST-EXIT-PGM         PIC  X(01).                            151030 
                88  MUST-EXIT-PGM          VALUE 'Y'.                             151030 
            03  WS88-CLAWBACK-REGP      PIC  X(01).                               151104 
                88  CLAWBACK-REGP                  VALUE 'Y'.                     151104 
                88  NOT-CLAWBACK-REGP              VALUE 'N'.                     151104 
            03  WS88-ARRAY-CRTABLE-FOUND      PIC  X(01).                         151109 
                88  ARRAY-CRTABLE-FOUND            VALUE 'Y'.                     151109 
                88  NOT-ARRAY-CRTABLE-FOUND        VALUE 'N'.                     151109 
            03  WS88-FIND-COMM                PIC  X(01).                         151109 
                88  FIND-COMM                      VALUE 'Y'.                     151109 
                88  NOT-FIND-COMM                  VALUE 'N'.                     151109 
            03  WS88-VALID-RECORD             PIC  X(01).                         151114 
                88  VALID-RECORD                   VALUE 'Y'.                     151114 
                88  NOT-VALID-RECORD               VALUE 'N'.                     151114 
            03  WS88-CHECK-AGENT              PIC  X(01).                <ATHA67> 160414 
                88  CHECK-AGENT                    VALUE 'Y'.            <ATHA67> 160414 
                88  NOT-CHECK-AGENT                VALUE 'N'.            <ATHA67> 160414 
            03  WS88-ARRAY-ACMV-FOUND         PIC  X(01).                <ATHA67> 160513 
                88  ARRAY-ACMV-FOUND               VALUE 'Y'.            <ATHA67> 160513 
                88  NOT-ARRAY-ACMV-FOUND           VALUE 'N'.            <ATHA67> 160513 
            03  WS88-MUST-EXIT-LOOP           PIC  X(01).                <ATHB45> 170313 
                88  MUST-EXIT-LOOP            VALUE 'Y'.                 <ATHB45> 170313 
                88  NOT-MUST-EXIT-LOOP        VALUE 'N'.                 <ATHB45> 170313 
            03  WS88-CRTABLE-TYPE             PIC  X(01).                <ATHB45> 170313 
                88  CRTABLE-TYPE-TOP-UP       VALUE 'P'.                 <ATHB45> 170313 
                88  CRTABLE-TYPE-UL           VALUE 'L'.                 <ATHD11> 181016 
            03  WS88-CLAWBACK-COVER           PIC  X(01).                <ATHD11> 181018 
               88  CLAWBACK-COVER             VALUE 'Y'.                 <ATHD11> 181018 
               88  NOT-CLAWBACK-COVER         VALUE 'N'.                 <ATHD11> 181018 
            03  WS88-MCPPI-PRODUCT         PIC  X(01).                   <ATHD11> 181019 
               88  MCPPI-PRODUCT           VALUE 'Y'.                    <ATHD11> 181019 
               88  NOT-MCPPI-PRODUCT       VALUE 'N'.                    <ATHD11> 181019 
       /                                                                          151030 
            COPY SYSERRREC.                                                       151030 
            COPY VFLAGCPY.                                                        151030 
            COPY FREQCPY.                                                         151030 
            COPY VARCOM.                                                          151030 
            COPY SMTPFXCPY.                                                       151030 
            COPY FSUPFXCPY.                                                       151030 
       /                                                                          151030 
            COPY ITEMSKM.                                                         151030 
            COPY ITDMSKM.                                                         151030 
       /                                                                          151030 
            COPY T5645REC.                                                        151030 
            COPY T8Z82REC.                                                        151030 
            COPY T7Z11REC.                                               <ATHB37> 170214 
            COPY T5Z01REC.                                               <ATHB37> 170214 
            COPY T5694REC.                                               <ATHB37> 170302 
            COPY T5687REC.                                               <ATHB45> 170313 
            COPY T5673REC.                                               <ATHB45> 170313 
            COPY T8Z05REC.                                               <ATHD11> 181019 
       /                                                                          151030 
            COPY DATCON2REC.                                                      151030 
            COPY DATCON3REC.                                                      151030 
            COPY DATCON4REC.                                                      151030 
       /                                                                          151030 
            COPY ACMVBK3SKM.                                                      151030 
            COPY ACMVREVSKM.                                                      151109 
            COPY ZTUDSKM.                                                         151030 
            COPY ZCHDSKM.                                                         151104 
            COPY ZCHASKM.                                                         151110 
            COPY AGNTSKM.                                                         151109 
            COPY AGLFSKM.                                                         151113 
            COPY CHDRMJASKM.                                                      151103 
            COPY AGCMBCRSKM.                                                      151104 
            COPY ZTUHSKM.                                                         151110 
            COPY ZCLBSKM.                                                         151112 
            COPY ZCLBCOVSKM.                                             <ATHA67> 160404 
            COPY ZTUHTRNSKM.                                                      151110 
            COPY ZCOVCRTSKM.                                             <ATHB45> 170310 
            COPY PTRNREVSKM.                                                      151114 
            COPY COVRAFISKM.                                             <ATHB37> 170210 
            COPY CHDRAFISKM.                                             <ATHB37> 170210 
            COPY DESCSKM.                                                         151116 
       /                                                                          151111 
            COPY LIFACMVREC.                                                      151111 
            COPY ALOCNOREC.                                                       151112 
                                                                                  151030 
        LINKAGE SECTION.                                                          151030 
       *****************                                                          151030 
            COPY ZSCLABCKC.                                                       151030 
       /                                                                          151030 
        PROCEDURE DIVISION           USING ZSCLABCK-REC.                          151030 
                                                                                  151030 
       *****************************************************************          151030 
       *      CALL ALL THE SECTIONS                                               151030 
       *****************************************************************          151030 
        0000-SUBROUTINE-MAIN SECTION.                                             151030 
       ******************************                                             151030 
        0000-START.                                                               151030 
                                                                                  151030 
            PERFORM 1000-INITIALISE                                               151030 
            IF  MUST-EXIT-PGM                                                     151111 
                GO TO 0000-EXIT                                                   151111 
            END-IF                                                                151111 
            PERFORM 2000-PROCESS                                                  151030 
            IF  ZSCLABCK-STATUZ        NOT = O-K                                  151030 
                GO TO 0000-EXIT                                                   151030 
            END-IF                                                                151030 
            PERFORM 3000-TERMINATION                                              151030 
            .                                                                     151030 
        0000-EXIT.                                                                151030 
             EXIT PROGRAM.                                                        151030 
       /                                                                          151030 
        1000-INITIALISE SECTION.                                                  151110 
       *************************                                                  151030 
        1000-START.                                                               151030 
                                                                                  151030 
       * Initialize Variables                                                     151030 
            INITIALIZE WSAA-VARIABLES                                             151030 
            INITIALIZE WS88-CONTROL-FLAGS                                         151030 
            INITIALIZE LIFA-LIFACMV-REC                                           151111 
            MOVE O-K                    TO ZSCLABCK-STATUZ                        151030 
            SET NOT-CLAWBACK-REGP       TO TRUE                                   151104 
            SET CHECK-AGENT             TO TRUE                          <ATHA67> 160414 
                                                                                  151103 
            PERFORM 1300-READ-CHDRMJA                                             151104 
            PERFORM 1400-READ-ZCHD                                                151104 
            PERFORM 1500-READ-AGCMBCR                                             151104 
                                                                                  151104 
       ***  PERFORM 1600-VALIDATE-AGENT                                  <ATHA43> 160317 
                                                                                  151110 
            PERFORM X1800-RETRIEVE-ZCHA-AGNTNUM                                   151110 
                                                                         <ATHA43> 160317 
            PERFORM 1600-VALIDATE-AGENT                                  <ATHA43> 160317 
                                                                                  151105 
            PERFORM 1700-FIND-NEXT-ANNI                                           151105 
            IF  MUST-EXIT-PGM                                            <ATHB37> 170208 
                GO TO 1000-EXIT                                          <ATHB37> 170208 
            END-IF                                                       <ATHB37> 170208 
                                                                                  151104 
            PERFORM 1100-OBTAIN-CLAWBACK-RULES                                    151103 
            IF  MUST-EXIT-PGM                                                     151111 
                GO TO 1000-EXIT                                                   151111 
            END-IF                                                                151111 
                                                                         <ATHB37> 170208 
            MOVE CHDRMJA-OCCDATE        TO WSAA-FROM-DATE                         151109 
            PERFORM X900-CLAWBACK-RULES-PERC                                      151108 
            IF  WSAA-T8Z82               = ZEROS                                  151124 
                SET NOT-CLAWBACK-REGP   TO TRUE                                   151124 
            END-IF                                                                151124 
            PERFORM 1200-READ-T5645                                               151112 
                                                                         <ATHA43> 160225 
            MOVE ZSCLABCK-PARTS-PERC   TO WSAA-PARTS-PERC                <ATHA43> 160225 
            IF  WSAA-PARTS-PERC         = ZEROS                          <ATHA43> 160225 
                MOVE 100               TO WSAA-PARTS-PERC                <ATHA43> 160225 
            END-IF                                                       <ATHA43> 160225 
            COMPUTE WSAA-PARTS-PERC-WRK ROUNDED                          <ATHA43> 160324 
                                         = WSAA-PARTS-PERC               <ATHA43> 160324 
                                         / 100                           <ATHA43> 160324 
            .                                                                     151030 
        1000-EXIT.                                                                151030 
            EXIT.                                                                 151030 
 0482.00                                                                                  151103 
 0483.00        1100-OBTAIN-CLAWBACK-RULES  SECTION.                                      151103 
 0484.00       ***********************************                                        151103 
 0485.00        1100-START.                                                               151103 
 0486.00                                                                                  151103 
 0487.00                                                                                  151103 
 0488.00            MOVE SPACES                 TO ITDM-DATA-KEY                          151103 
 0489.00            MOVE ZSCLABCK-CHDRCOY       TO ITDM-ITEMCOY                           151103 
 0490.00            MOVE T8Z82                  TO ITDM-ITEMTABL                          151103 
 0491.00       **   MOVE CHDRMJA-SRCEBUS        TO WSAA-ITEM-SRCEBUS                      151222 
 0492.00            MOVE CHDRMJA-CNTTYPE        TO WSAA-ITEM-CNTTYPE                      151222 
 0493.00                                                                                  151103 
 0494.00       **   IF  ZSCLABCK-CRTABLE     NOT = SPACES                        <ATHB37> 170214 
 0495.00       **       MOVE ZSCLABCK-CRTABLE   TO WSAA-ITEM-CRTABLE             <ATHB37> 170214 
 0496.00       **   ELSE                                                         <ATHB37> 170214 
 0497.00                MOVE '****'             TO WSAA-ITEM-CRTABLE                      151103 
 0498.00       **   END-IF                                                       <ATHB37> 170214 
 0499.00            MOVE WSAA-ITEMITEM          TO ITDM-ITEMITEM                          151103 
 0500.00            MOVE ZSCLABCK-EFFDATE       TO ITDM-ITMFRM                            151103 
 0501.00            MOVE ITDMREC                TO ITDM-FORMAT                            151103 
 0502.00            MOVE BEGN                   TO ITDM-FUNCTION                          151103 
 0503.00                                                                                  151103 
 0504.00            CALL 'ITDMIO'            USING ITDM-PARAMS                            151103 
 0505.00                                                                                  151103 
 0506.00            IF  ITDM-STATUZ           NOT = O-K                                   151103 
 0507.00            AND ITDM-STATUZ           NOT = ENDP                                  151103 
 0508.00                MOVE ITDM-PARAMS        TO SYSR-PARAMS                            151103 
 0509.00                MOVE ITDM-STATUZ        TO SYSR-STATUZ                            151103 
 0510.00                PERFORM 9000-FATAL-ERROR                                          151103 
 0511.00            END-IF                                                                151103 
 0512.00                                                                                  151103 
 0513.00            IF  ITDM-ITEMCOY         NOT = ZSCLABCK-CHDRCOY                       151103 
 0514.00            OR  ITDM-ITEMTABL        NOT = T8Z82                                  151103 
 0515.00            OR  ITDM-ITEMITEM        NOT = WSAA-ITEMITEM                          151103 
 0516.00            OR  ITDM-STATUZ              = ENDP                                   151103 
 0517.00                MOVE 'Y'                TO WS88-MUST-EXIT-PGM                     151111 
 0518.00                GO TO 1100-EXIT                                                   151111 
 0519.00            ELSE                                                                  151103 
 0520.00                MOVE ITDM-GENAREA       TO T8Z82-T8Z82-REC                        151103 
 0521.00            END-IF                                                                151103 
 0522.00                                                                                  151103 
 0523.00            .                                                                     151103 
 0524.00        1100-EXIT.                                                                151103 
 0525.00            EXIT.                                                                 151103 
 0526.00       /                                                                          151112 
 0527.00        1200-READ-T5645  SECTION.                                                 151112 
 0528.00       **************************                                                 151112 
 0529.00        1200-START.                                                               151112 
 0530.00       *                                                                          151112 
 0531.00       *  Read Additional Commission Accounting Rules                             151112 
 0532.00       *                                                                          151112 
 0533.00            INITIALIZE ITEMREC-KEY-DATA     OF ITEM-PARAMS                        151112 
 0534.00            INITIALIZE ITEMREC-NON-KEY-DATA OF ITEM-PARAMS                        151112 
 0535.00            MOVE 'IT'                   TO ITEM-ITEMPFX                           151112 
 0536.00            MOVE ZSCLABCK-CHDRCOY       TO ITEM-ITEMCOY                           151112 
 0537.00            MOVE T5645                  TO ITEM-ITEMTABL                          151112 
 0538.00            MOVE 'ZSCLAWBA'             TO ITEM-ITEMITEM                          151113 
 0539.00            MOVE BEGN                   TO ITEM-FUNCTION                          151113 
 0540.00                                                                                  151112 
 0541.00            MOVE 1                      TO WSAA-T5645-SUB                         151113 
 0542.00            MOVE 1                      TO WSAA-T5645-OFFSET             <ATHB37> 170302 
 0543.00       ***  PERFORM X100-ITEM-IO                                                  151113 
 0544.00                                                                                  151112 
 0545.00            MOVE ITEM-GENAREA           TO T5645-T5645-REC                        151112 
 0546.00            PERFORM 1250-LOAD-T5645  UNTIL ITEM-STATUZ                            151113 
 0547.00                                        = ENDP                                    151113 
 0548.00            .                                                                     151112 
 0549.00        1200-EXIT.                                                                151112 
 0550.00             EXIT.                                                                151112 
 0551.00       /                                                                          151113 
 0552.00        1250-LOAD-T5645 SECTION.                                                  151113 
 0553.00       ************************                                                   151113 
 0554.00        1250-START.                                                               151113 
 0555.00                                                                                  151113 
 0556.00            CALL 'ITEMIO'            USING ITEM-PARAMS                            151113 
 0557.00                                                                                  151113 
 0558.00            IF  ZSCLABCK-CHDRCOY     NOT = ITEM-ITEMCOY                           151113 
 0559.00            OR  ITEM-ITEMTABL        NOT = T5645                                  151113 
 0560.00            OR  ITEM-ITEMITEM        NOT = 'ZSCLAWBA'                             151113 
 0561.00            OR  ITEM-STATUZ          NOT = O-K                                    151113 
 0562.00                IF  ITEM-FUNCTION        = BEGN                                   151113 
 0563.00                    MOVE ITEM-PARAMS    TO SYSR-PARAMS                            151113 
 0564.00                    PERFORM 9000-FATAL-ERROR                                      151113 
 0565.00               ELSE                                                               151113 
 0566.00                    MOVE ENDP              TO ITEM-STATUZ                         151113 
 0567.00                    GO TO 1250-EXIT                                               151113 
 0568.00                END-IF                                                            151113 
 0569.00            END-IF                                                                151113 
 0570.00                                                                                  151113 
 0571.00            MOVE ITEM-GENAREA            TO T5645-T5645-REC                       151113 
 0572.00                                                                                  151113 
 0573.00            MOVE 1                       TO WSAA-T5645-SUB                        151113 
 0574.00                                                                                  151113 
 0575.00            IF  WSAA-T5645-SUB           > WSAA-T5645-SIZE                        151113 
 0576.00                MOVE H791               TO SYSR-STATUZ                            151113 
 0577.00                MOVE T5645              TO SYSR-PARAMS                            151113 
 0578.00                PERFORM 9000-FATAL-ERROR                                          151113 
 0579.00            END-IF                                                                151113 
 0580.00                                                                                  151113 
 0581.00            PERFORM UNTIL WSAA-T5645-SUB > 15                                     151113 
 0582.00                                                                                  151113 
 0583.00               MOVE T5645-CNTTOT(WSAA-T5645-SUB)                                  151113 
 0584.00                                        TO WSAA-T5645-CNTTOT                      151113 
 0585.00                                           (WSAA-T5645-OFFSET)                    151113 
 0586.00               MOVE T5645-GLMAP(WSAA-T5645-SUB)                                   151113 
 0587.00                                        TO WSAA-T5645-GLMAP                       151113 
 0588.00                                           (WSAA-T5645-OFFSET)                    151113 
 0589.00               MOVE T5645-SACSCODE(WSAA-T5645-SUB)                                151113 
 0590.00                                        TO WSAA-T5645-SACSCODE                    151113 
 0591.00                                           (WSAA-T5645-OFFSET)                    151113 
 0592.00               MOVE T5645-SACSTYPE(WSAA-T5645-SUB)                                151113 
 0593.00                                        TO WSAA-T5645-SACSTYPE                    151113 
 0594.00                                           (WSAA-T5645-OFFSET)                    151113 
 0595.00               MOVE T5645-SIGN(WSAA-T5645-SUB)                                    151113 
 0596.00                                        TO WSAA-T5645-SIGN                        151113 
 0597.00                                           (WSAA-T5645-OFFSET)                    151113 
 0598.00                                                                                  151113 
 0599.00               ADD 1                    TO WSAA-T5645-SUB                         151113 
 0600.00               ADD 1                    TO WSAA-T5645-OFFSET                      151113 
 0601.00                                                                                  151113 
 0602.00            END-PERFORM                                                           151113 
 0603.00                                                                                  151113 
 0604.00            MOVE NEXTR                  TO ITEM-FUNCTION                          151113 
 0605.00            .                                                                     151113 
 0606.00        1250-EXIT.                                                                151113 
 0607.00            EXIT.                                                                 151113 
 0608.00       /                                                                          151103 
 0609.00        1300-READ-CHDRMJA  SECTION.                                               151103 
 0610.00       ***********************************                                        151103 
 0611.00        1300-START.                                                               151103 
 0612.00                                                                                  151103 
 0613.00            INITIALIZE CHDRMJAREC-KEY-DATA     OF CHDRMJA-PARAMS                  151103 
 0614.00            INITIALIZE CHDRMJAREC-NON-KEY-DATA OF CHDRMJA-PARAMS                  151103 
 0615.00                                                                                  151103 
 0616.00            MOVE ZSCLABCK-CHDRCOY       TO CHDRMJA-CHDRCOY                        151103 
 0617.00            MOVE ZSCLABCK-CHDRNUM       TO CHDRMJA-CHDRNUM                        151103 
 0618.00            MOVE READR                  TO CHDRMJA-FUNCTION                       151103 
 0619.00                                                                                  151103 
 0620.00            PERFORM X500-CHDRMJA-IO                                               151104 
 0621.00            MOVE CHDRMJA-OCCDATE        TO WSAA-OCCDATE                           151123 
 0622.00                                                                                  151104 
 0623.00            .                                                                     151103 
 0624.00        1300-EXIT.                                                                151103 
 0625.00            EXIT.                                                                 151103 
 0626.00       /                                                                          151104 
 0627.00        1400-READ-ZCHD  SECTION.                                                  151104 
 0628.00       ***********************************                                        151104 
 0629.00        1400-START.                                                               151104 
 0630.00                                                                                  151104 
 0631.00            INITIALIZE ZCHDREC-KEY-DATA     OF ZCHD-PARAMS                        151104 
 0632.00            INITIALIZE ZCHDREC-NON-KEY-DATA OF ZCHD-PARAMS                        151104 
 0633.00                                                                                  151104 
 0634.00            MOVE ZSCLABCK-CHDRCOY       TO ZCHD-CHDRCOY                           151104 
 0635.00            MOVE ZSCLABCK-CHDRNUM       TO ZCHD-CHDRNUM                           151104 
 0636.00            MOVE READR                  TO ZCHD-FUNCTION                          151104 
 0637.00                                                                                  151104 
 0638.00            PERFORM X400-ZCHD-IO                                                  151104 
 0639.00                                                                                  151104 
 0640.00            .                                                                     151104 
 0641.00        1400-EXIT.                                                                151104 
 0642.00            EXIT.                                                                 151104 
 0643.00       /                                                                          151104 
 0644.00        1500-READ-AGCMBCR SECTION.                                                151104 
 0645.00       ****************************                                               151104 
 0646.00        1500-START.                                                               151104 
 0647.00                                                                                  151104 
 0648.00            INITIALIZE AGCMBCRREC-KEY-DATA     OF AGCMBCR-PARAMS                  151104 
 0649.00            INITIALIZE AGCMBCRREC-NON-KEY-DATA OF AGCMBCR-PARAMS                  151104 
 0650.00                                                                                  151104 
 0651.00            MOVE ZSCLABCK-CHDRCOY       TO AGCMBCR-CHDRCOY                        151104 
 0652.00            MOVE ZSCLABCK-CHDRNUM       TO AGCMBCR-CHDRNUM                        151104 
 0653.00            MOVE WSCC-01                TO AGCMBCR-LIFE                           151104 
 0654.00            MOVE WSCC-01                TO AGCMBCR-COVERAGE                       151104 
 0655.00            MOVE WSCC-00                TO AGCMBCR-RIDER                          151104 
 0656.00            MOVE WSCC-MAX-TRANNO        TO AGCMBCR-TRANNO                         151104 
 0657.00            MOVE BEGN                   TO AGCMBCR-FUNCTION                       151104 
 0658.00                                                                                  151104 
 0659.00            PERFORM X300-AGCMBCR-IO                                               151104 
 0660.00            .                                                                     151104 
 0661.00        1500-EXIT.                                                                151104 
 0662.00            EXIT.                                                                 151104 
 0663.00       /                                                                          151104 
 0664.00        1600-VALIDATE-AGENT SECTION.                                              151104 
 0665.00       ****************************                                               151104 
 0666.00        1600-START.                                                               151104 
 0667.00                                                                                  151104 
 0668.00            MOVE ZCHD-AGNTNUM       TO WSAA-AGNTNUM-INIT                          151123 
 0669.00            MOVE ZCHD-AGNTNUM       TO WSAA-AGNTNUM                               151123 
 0670.00            PERFORM X600-READ-AGNT                                       <ATHA43> 160317 
 0671.00            MOVE AGNT-CLNTNUM       TO WSAA-ZCHD-CLNTNUM                 <ATHA43> 160317 
 0672.00            IF  ZCHD-AGNTNUM         NOT = AGCMBCR-AGNTNUM                        151104 
 0673.00       ***      PERFORM X600-READ-AGNT                                   <ATHA43> 160317 
 0674.00       ***      MOVE AGNT-CLNTNUM       TO WSAA-ZCHD-CLNTNUM             <ATHA43> 160317 
 0675.00                MOVE AGCMBCR-AGNTNUM    TO WSAA-AGNTNUM                           151123 
 0676.00                PERFORM X600-READ-AGNT                                            151104 
 0677.00                MOVE AGNT-CLNTNUM       TO WSAA-AGCM-CLNTNUM                      151104 
 0678.00                IF  WSAA-ZCHD-CLNTNUM    = WSAA-AGCM-CLNTNUM                      151104 
 0679.00                    SET CLAWBACK-REGP   TO TRUE                                   151104 
 0680.00                END-IF                                                            151104 
 0681.00            ELSE                                                                  151104 
 0682.00                SET CLAWBACK-REGP       TO TRUE                                   151104 
 0683.00            END-IF                                                                151104 
 0684.00                                                                         <ATHA43> 160317 
 0685.00            IF  CLAWBACK-REGP                                            <ATHA43> 160317 
 0686.00                IF WSAA-ZCHD-CLNTNUM NOT = WSAA-ZCHA-CLNTNUM             <ATHA43> 160317 
 0687.00                   SET NOT-CLAWBACK-REGP TO TRUE                         <ATHA43> 160317 
 0688.00                END-IF                                                   <ATHA43> 160317 
 0689.00            END-IF                                                       <ATHA43> 160317 
 0690.00            .                                                                     151104 
 0691.00        1600-EXIT.                                                                151104 
 0692.00            EXIT.                                                                 151104 
 0693.00       /                                                                          151105 
 0694.00        1700-FIND-NEXT-ANNI SECTION.                                              151105 
 0695.00       ****************************                                               151105 
 0696.00        1700-START.                                                               151105 
 0697.00                                                                         <ATHB37> 170208 
 0698.00             IF ZSCLABCK-FUNCTION        = WSCC-DECRP                    <ATHB37> 170208 
 0699.00                PERFORM X3500-FIND-ANNIVERSARY                           <ATHB37> 170208 
 0700.00             ELSE                                                        <ATHB37> 170208 
 0701.00                                                                         <ATHB37> 170208 
 0702.00             INITIALIZE DTC4-DATCON4-REC                                          151105 
 0703.00             MOVE CHDRMJA-OCCDATE       TO DTC4-INT-DATE-1                        151105 
 0704.00             MOVE WSCC-01               TO DTC4-FREQUENCY                         151105 
 0705.00             MOVE 1                     TO DTC4-FREQ-FACTOR                       151105 
 0706.00                                                                                  151105 
 0707.00             CALL 'DATCON4'          USING DTC4-DATCON4-REC                       151105 
 0708.00                                                                                  151105 
 0709.00             IF  DTC4-STATUZ         NOT = O-K                                    151105 
 0710.00                 MOVE DTC4-DATCON4-REC                                            151105 
 0711.00                                        TO SYSR-PARAMS                            151105 
 0712.00                 MOVE DTC4-STATUZ       TO SYSR-STATUZ                            151105 
 0713.00                 PERFORM 9000-FATAL-ERROR                                         151105 
 0714.00             END-IF                                                               151105 
 0715.00             MOVE DTC4-INT-DATE-2       TO WSAA-NEXT-ANNI-DATE                    151105 
 0716.00             END-IF                                                      <ATHB37> 170208 
 0717.00            .                                                                     151105 
 0718.00        1700-EXIT.                                                                151105 
 0719.00            EXIT.                                                                 151105 
 0720.00       /                                                                          151030 
 0721.00        2000-PROCESS SECTION.                                                     151030 
 0722.00       **********************                                                     151030 
 0723.00        2000-START.                                                               151030 
 0724.00            SET NOT-CLAWBACK-COVER      TO TRUE                          <ATHD11> 181018 
 0725.00                                                                                  151030 
 0726.00            EVALUATE ZSCLABCK-FUNCTION                                            151030 
 0727.00       * FULL SURRENDER REGULAR AND TOP UP                                        151111 
 0728.00            WHEN WSCC-SURFS                                                       151111 
 0729.00                 PERFORM 2200-SURFS-CLAWBACK                                      151111 
 0730.00       * FULL SURRENDER REGULAR ONLY                                              151111 
 0731.00            WHEN WSCC-SURRF                                                       151111 
 0732.00       ****     IF  CLAWBACK-REGP                                        <ATHD11> 181012 
 0733.00       ****         PERFORM 2250-READ-ACMV                               <ATHD11> 181012 
 0734.00       ****     END-IF                                                   <ATHD11> 181012 
 0735.00                                                                         <ATHD11> 181012 
 0736.00                PERFORM 2900-SURRF-CLAWBACK                              <ATHD11> 181012 
 0737.00       * FULL SURRENDER TOP UP ONLY                                               151111 
 0738.00            WHEN WSCC-SURTF                                                       151111 
 0739.00                 PERFORM X4400-GET-TU-COVR                               <ATHB45> 170313 
 0740.00                 IF  WSAA-TU-CRTABLE NOT = SPACES                        <ATHB45> 170313 
 0741.00                     PERFORM X4800-READ-ZCOVCRT                          <ATHB45> 170313 
 0742.00                 END-IF                                                  <ATHB45> 170313 
 0743.00                 PERFORM 2270-READ-ZTUD-TOPUP                            <ATHB45> 170313 
 0744.00                 PERFORM 2280-READ-ZTUD-ARRAY                                     151111 
 0745.00       ***       PERFORM 2290-WRITE-LIFA-TOPUP                           <ATHA67> 160407 
 0746.00       * CFI MCPPI                                                       <ATHA67> 160408 
 0747.00            WHEN WSCC-SURCF                                                       151116 
 0748.00                 PERFORM 2400-SURCF-CLAWBACK                                      151116 
 0749.00       * PART SURRENDER MCPPI                                            <ATHA67> 160407 
 0750.00            WHEN WSCC-SURPS                                              <ATHA43> 160205 
 0751.00                 PERFORM 2300-SURP-CLAWBACK                                       151111 
 0752.00       * PART SURRENDER PER COVER (ULTIMA)                               <ATHD11> 181016 
 0753.00            WHEN WSCC-SURPC                                              <ATHD11> 181016 
 0754.00                 PERFORM 2950-SURPC-CLAWBACK                             <ATHD11> 181016 
 0755.00       * SINGLE PREMIUM                                                  <ATHA67> 160408 
 0756.00            WHEN WSCC-SURSP                                                       151122 
 0757.00                 PERFORM 2500-SURSP-CLAWBACK                                      151122 
 0758.00       * SINGLE PREMIUM MCPPI (SURRENDER)                                <ATHA67> 160413 
 0759.00            WHEN WSCC-SURGG                                              <ATHA67> 160407 
 0760.00            WHEN WSCC-SURGP                                              <ATHC41> 180308 
 0761.00                 PERFORM 2600-SURGG-CLAWBACK                             <ATHA67> 160407 
 0762.00       * SINGLE PREMIUM MCPPI (CFI)                                      <ATHA67> 160413 
 0763.00            WHEN WSCC-CFIGG                                              <ATHA67> 160413 
 0764.00                 PERFORM 2700-CFIGG-CLAWBACK                             <ATHA67> 160413 
 0765.00       * DECREASE PREMIUM CLAWBACK FOR REGULAR PREM ONLY                 <ATHB37> 170208 
 0766.00            WHEN WSCC-DECRP                                              <ATHB37> 170208 
 0767.00                 PERFORM 2800-DECRESE-PREM-CLAWBACK                      <ATHB37> 170208 
 0768.00            WHEN OTHER                                                            151030 
 0769.00                 MOVE BOMB              TO ZSCLABCK-STATUZ                        151030 
 0770.00            END-EVALUATE                                                          151030 
 0771.00                                                                                  151111 
 0772.00            IF  ZSCLABCK-STATUZ        NOT = O-K                                  151030 
 0773.00                GO TO 2000-EXIT                                                   151030 
 0774.00            END-IF                                                                151030 
 0775.00            .                                                                     151030 
 0776.00        2000-EXIT.                                                                151030 
 0777.00            EXIT.                                                                 151030 
 0778.00       /                                                                          151030 
 0779.00        2200-SURFS-CLAWBACK SECTION.                                              151111 
 0780.00       ****************************                                               151030 
 0781.00        2200-START.                                                               151030 
 0782.00            IF  CLAWBACK-REGP                                            <ATHA67> 160408 
 0783.00                IF WSAA-ZCHD-CLNTNUM NOT = WSAA-ZCHA-CLNTNUM             <ATHA67> 160408 
 0784.00                   SET NOT-CLAWBACK-REGP TO TRUE                         <ATHA67> 160408 
 0785.00                END-IF                                                   <ATHA67> 160408 
 0786.00            END-IF                                                       <ATHA67> 160408 
 0787.00                                                                                  151104 
 0788.00       * FOR REGULAR PREMIUM                                                      151109 
 0789.00            IF  CLAWBACK-REGP                                                     151104 
 0790.00                PERFORM 2250-READ-ACMV                                            151104 
 0791.00            END-IF                                                                151104 
 0792.00            PERFORM 2257-READ-ZTUD-REGP                                  <ATHA43> 160323 
 0793.00                                                                                  151103 
 0794.00       * FOR TOP UP                                                               151030 
 0795.00            PERFORM X4400-GET-TU-COVR                                    <ATHB45> 170313 
 0796.00            IF  WSAA-TU-CRTABLE NOT = SPACES                             <ATHB45> 170313 
 0797.00                PERFORM X4800-READ-ZCOVCRT                               <ATHB45> 170313 
 0798.00            END-IF                                                       <ATHB45> 170313 
 0799.00            PERFORM 2270-READ-ZTUD-TOPUP                                          151030 
 0800.00            PERFORM 2280-READ-ZTUD-ARRAY                                          151110 
 0801.00            PERFORM 2290-WRITE-LIFA-TOPUP                                         151214 
 0802.00            .                                                                     151030 
 0803.00        2200-EXIT.                                                                151030 
 0804.00            EXIT.                                                                 151030 
 0805.00       /                                                                          151030 
 0806.00        2250-READ-ACMV  SECTION.                                                  151030 
 0807.00       *********************************                                          151030 
 0808.00        2250-START.                                                               151030 
 0809.00                                                                                  151030 
 0810.00            INITIALIZE WSAA-ACMV-ARRAY                                   <ATHA67> 160513 
 0811.00            MOVE ZEROS                  TO WSAA-LAST-TRANNO                       151216 
 0812.00            MOVE ZEROS                  TO WSAA-ACMV-ARRAY-CNT           <ATHA67> 160513 
 0813.00            MOVE ZEROS                  TO WSAA-LAST-TRANNO-W                     151216 
 0814.00            MOVE ZSCLABCK-CHDRNUM        TO WSAA-ACMV-CHDRNUM                     151109 
 0815.00            MOVE '01'                   TO WSAA-ACMV-LIFE                         151030 
 0816.00            MOVE '01'                   TO WSAA-ACMV-COVERAGE                     151030 
 0817.00            MOVE '00'                   TO WSAA-ACMV-RIDER                        151030 
 0818.00            MOVE '00'                   TO WSAA-ACMV-PLAN-SUFF                    151030 
 0819.00                                                                         <ATHA67> 160513 
 0820.00            INITIALIZE ACMVBK3-PARAMS                                             151030 
 0821.00            INITIALIZE ACMVBK3REC-KEY-DATA     OF ACMVBK3-PARAMS                  151030 
 0822.00            INITIALIZE ACMVBK3REC-NON-KEY-DATA OF ACMVBK3-PARAMS                  151030 
 0823.00            MOVE ZSCLABCK-CHDRCOY       TO ACMVBK3-RLDGCOY                        151109 
 0824.00            MOVE WSAA-ACMV-RLDGACCT     TO ACMVBK3-RLDGACCT                       151030 
 0825.00            MOVE WSCC-LE                TO ACMVBK3-SACSCODE                       151030 
 0826.00            MOVE WSCC-YC                TO ACMVBK3-SACSTYP                        151106 
 0827.00            MOVE BEGN                   TO ACMVBK3-FUNCTION                       151030 
 0828.00            PERFORM X1100-ACMVBK3-IO                                              151030 
 0829.00            PERFORM                                                               151030 
 0830.00              UNTIL ACMVBK3-STATUZ       = ENDP                                   151030 
 0831.00                                                                                  151030 
 0832.00                 MOVE 'B522'            TO WSAA-BATCTRCDE                         151114 
 0833.00                 PERFORM X2200-READ-PTRNREV                                       151114 
 0834.00                                                                                  151114 
 0835.00                 IF  VALID-RECORD                                                 151114 
 0836.00                 IF  ACMVBK3-EFFDATE    >= WSAA-OCCDATE                           151104 
 0837.00                 AND ACMVBK3-EFFDATE    <  WSAA-NEXT-ANNI-DATE                    151104 
 0838.00                                                                         <ATHA67> 160513 
 0839.00                     PERFORM 2250A-LOAD-ARRAY-ACMV                       <ATHA67> 160513 
 0840.00                                                                         <ATHA67> 160513 
 0841.00                     MOVE ACMVBK3-TRANREF(1:8)                           <ATHA67> 160513 
 0842.00                                         TO WSAA-ACMV-AGNTNUM            <ATHA67> 160513 
 0843.00                                           (WSAA-ACMV-ARRAY-CNT)         <ATHA67> 160513 
 0844.00                     ADD ACMVBK3-ORIGAMT TO WSAA-ACMV-ZPREMAMT           <ATHA67> 160513 
 0845.00                                           (WSAA-ACMV-ARRAY-CNT)         <ATHA67> 160513 
 0846.00                                                                         <ATHA67> 160513 
 0847.00                     COMPUTE WSAA-PAID-PREM                                       151104 
 0848.00                                         = WSAA-PAID-PREM                         151104 
 0849.00                                         + ACMVBK3-ORIGAMT                        151030 
 0850.00                     IF  ACMVBK3-TRANNO NOT = WSAA-LAST-TRANNO                    151216 
 0851.00                     PERFORM  2255-FIND-COMMISSIONS                               151106 
 0852.00                     END-IF                                                       151216 
 0853.00                     MOVE ACMVBK3-TRANNO TO WSAA-LAST-TRANNO                      151216 
 0854.00                 END-IF                                                           151030 
 0855.00                 END-IF                                                           151114 
 0856.00                                                                                  151114 
 0857.00       **        MOVE 'T512'            TO WSAA-BATCTRCDE                <ATHA67> 160404 
 0858.00       **        PERFORM X2200-READ-PTRNREV                              <ATHA67> 160404 
 0859.00       **        IF  VALID-RECORD                                        <ATHA67> 160404 
 0860.00       **                                                                <ATHA67> 160404 
 0861.00       **            COMPUTE WSAA-PAID-PREM                              <ATHA67> 160404 
 0862.00       **                                = WSAA-PAID-PREM                <ATHA67> 160404 
 0863.00       **                                + ACMVBK3-ORIGAMT               <ATHA67> 160404 
 0864.00       **            IF  ACMVBK3-TRANNO NOT = WSAA-LAST-TRANNO-W         <ATHA67> 160404 
 0865.00       **            PERFORM  2255-FIND-COMMISSIONS                      <ATHA67> 160404 
 0866.00       **            END-IF                                              <ATHA67> 160404 
 0867.00       **            MOVE ACMVBK3-TRANNO TO WSAA-LAST-TRANNO-W           <ATHA67> 160404 
 0868.00       **        END-IF                                                  <ATHA67> 160404 
 0869.00                                                                                  151114 
 0870.00                 MOVE NEXTR             TO ACMVBK3-FUNCTION                       151030 
 0871.00                 PERFORM X1100-ACMVBK3-IO                                         151030 
 0872.00            END-PERFORM                                                           151030 
 0873.00                                                                                  151105 
 0874.00            IF ZSCLABCK-FUNCTION         = WSCC-SURCF                    <ATHA67> 160513 
 0875.00               PERFORM 2250C-CFI-CLAWBACK                                <ATHA67> 160513 
 0876.00            ELSE                                                         <ATHA67> 160513 
 0877.00               PERFORM 2250B-REGP-CLAWBACK                               <ATHA67> 160513 
 0878.00            END-IF                                                       <ATHA67> 160513 
 0879.00            .                                                                     151030 
 0880.00        2250-EXIT.                                                                151030 
 0881.00            EXIT.                                                                 151030 
 0882.00       /                                                                 <ATHA67> 160513 
 0883.00        2250A-LOAD-ARRAY-ACMV SECTION.                                   <ATHA67> 160513 
 0884.00       *********************************                                 <ATHA67> 160513 
 0885.00        2250A-START.                                                     <ATHA67> 160513 
 0886.00                                                                         <ATHA67> 160513 
 0887.00            SET  NOT-ARRAY-ACMV-FOUND   TO TRUE                          <ATHA67> 160513 
 0888.00                                                                         <ATHA67> 160513 
 0889.00            PERFORM VARYING WSAA-IND1 FROM 1 BY 1                        <ATHA67> 160513 
 0890.00              UNTIL WSAA-IND1            > WSCC-MAX-ARRAY                <ATHA67> 160513 
 0891.00              OR    WSAA-ACMV-AGNTNUM (WSAA-IND1)                        <ATHA67> 160513 
 0892.00                                         = SPACES                        <ATHA67> 160513 
 0893.00              OR    ARRAY-ACMV-FOUND                                     <ATHA67> 160513 
 0894.00                IF  ACMVBK3-TRANREF(1:8)                                 <ATHA67> 160513 
 0895.00                                         = WSAA-ACMV-AGNTNUM(WSAA-IND1)  <ATHA67> 160513 
 0896.00                    SET ARRAY-ACMV-FOUND                                 <ATHA67> 160513 
 0897.00                                        TO TRUE                          <ATHA67> 160513 
 0898.00                    MOVE WSAA-IND1      TO WSAA-ACMV-ARRAY-CNT           <ATHA67> 160513 
 0899.00                END-IF                                                   <ATHA67> 160513 
 0900.00                MOVE WSAA-IND1          TO WSAA-ACMV-ARRAY-CNT           <ATHA67> 160513 
 0901.00            END-PERFORM                                                  <ATHA67> 160513 
 0902.00                                                                         <ATHA67> 160513 
 0903.00            IF  ARRAY-ACMV-FOUND                                         <ATHA67> 160513 
 0904.00                GO TO 2250A-EXIT                                         <ATHA67> 160513 
 0905.00            END-IF                                                       <ATHA67> 160513 
 0906.00                                                                         <ATHA67> 160513 
 0907.00            ADD WSCC-NUM-1              TO WSAA-ACMV-ARRAY-CNT           <ATHA67> 160513 
 0908.00            .                                                            <ATHA67> 160513 
 0909.00        2250A-EXIT.                                                      <ATHA67> 160513 
 0910.00            EXIT.                                                        <ATHA67> 160513 
 0911.00       /                                                                 <ATHA67> 160513 
 0912.00        2250B-REGP-CLAWBACK SECTION.                                     <ATHA67> 160513 
 0913.00       *********************************                                 <ATHA67> 160513 
 0914.00        2250B-START.                                                     <ATHA67> 160513 
 0915.00            COMPUTE WSAA-PAID-PREM-CLAWB ROUNDED                         <ATHA67> 160513 
 0916.00                                         = (WSAA-PAID-PREM               <ATHA67> 160513 
 0917.00                                         * WSAA-T8Z82)                   <ATHA67> 160513 
 0918.00                                         *  WSAA-PARTS-PERC-WRK          <ATHA67> 160513 
 0919.00            COMPUTE WSAA-PAID-COMM-CLAWB ROUNDED                         <ATHA67> 160513 
 0920.00                                         = (WSAA-PAID-COMM               <ATHA67> 160513 
 0921.00                                         * WSAA-T8Z82)                   <ATHA67> 160513 
 0922.00                                         * WSAA-PARTS-PERC-WRK           <ATHA67> 160513 
 0923.00                                                                         <ATHA67> 160513 
 0924.00            COMPUTE WSAA-PAID-OVRCOM-CLAWB ROUNDED                       <ATHA67> 160513 
 0925.00                                         = (WSAA-PAID-OVRCOM             <ATHA67> 160513 
 0926.00                                         * WSAA-T8Z82)                   <ATHA67> 160513 
 0927.00                                         * WSAA-PARTS-PERC-WRK           <ATHA67> 160513 
 0928.00                                                                         <ATHA67> 160513 
 0929.00      ***   MOVE 'MCP2'                 TO WSAA-CRTABLE          <ATHB87><ATHA67> 170824 
 0930.00                                                                         <ATHA67> 160513 
 0931.00            MOVE '01'                   TO WSAA-ZCLB-LIFE                <ATHA67> 160513 
 0932.00            MOVE '01'                   TO WSAA-ZCLB-COVERAGE            <ATHA67> 160513 
 0933.00            MOVE '00'                   TO WSAA-ZCLB-RIDER               <ATHA67> 160513 
 0934.00            MOVE '00'                   TO WSAA-ZCLB-RECODE              <ATHA67> 160513 
 0935.00            PERFORM X5000-FIND-MAIN-COVR                                 <ATHB87> 170824 
 0936.00                                                                         <ATHB87> 170824 
 0937.00            PERFORM X3000-READ-ZCLBCOV                                   <ATHA67> 160513 
 0938.00            PERFORM X3100-FIND-CLAWB-REMN-REGP                           <ATHA67> 160513 
 0939.00                                                                         <ATHA67> 160513 
 0940.00            PERFORM X1900-WRITE-ZCLB                                     <ATHA67> 160513 
 0941.00                                                                         <ATHA67> 160513 
 0942.00            PERFORM X1400-WRITE-LIFA-REGP                                <ATHA67> 160513 
 0943.00            PERFORM X2000-DUE-ACCOUNTINGS                                <ATHA67> 160513 
 0944.00            PERFORM X2100-COLL-ACCOUNTINGS                               <ATHA67> 160513 
 0945.00            .                                                            <ATHA67> 160513 
 0946.00        2250B-EXIT.                                                      <ATHA67> 160513 
 0947.00            EXIT.                                                        <ATHA67> 160513 
 0948.00       /                                                                 <ATHA67> 160513 
 0949.00        2250C-CFI-CLAWBACK SECTION.                                      <ATHA67> 160513 
 0950.00       *********************************                                 <ATHA67> 160513 
 0951.00        2250C-START.                                                     <ATHA67> 160513 
 0952.00              PERFORM VARYING WSAA-IND1 FROM 1 BY 1                      <ATHA67> 160513 
 0953.00                UNTIL WSAA-IND1          > WSAA-ACMV-ARRAY-CNT           <ATHA67> 160513 
 0954.00                                                                         <ATHA67> 160513 
 0955.00                MOVE WSAA-ACMV-ZPREMAMT(WSAA-IND1)                       <ATHA67> 160513 
 0956.00                                        TO WSAA-PAID-PREM                <ATHA67> 160513 
 0957.00                MOVE WSAA-ACMV-ZCOMMAMT(WSAA-IND1)                       <ATHA67> 160513 
 0958.00                                        TO WSAA-PAID-COMM                <ATHA67> 160513 
 0959.00                MOVE WSAA-ACMV-OVRAMT  (WSAA-IND1)                       <ATHA67> 160513 
 0960.00                                        TO WSAA-PAID-OVRCOM              <ATHA67> 160513 
 0961.00                MOVE WSAA-ACMV-AGNTNUM (WSAA-IND1)                       <ATHA67> 160513 
 0962.00                                        TO WSAA-AGNTNUM                  <ATHA67> 160513 
 0963.00                COMPUTE WSAA-PAID-PREM-CLAWB ROUNDED                     <ATHA67> 160513 
 0964.00                                         = (WSAA-PAID-PREM               <ATHA67> 160513 
 0965.00                                         * WSAA-T8Z82)                   <ATHA67> 160513 
 0966.00                                         *  WSAA-PARTS-PERC-WRK          <ATHA67> 160513 
 0967.00                COMPUTE WSAA-PAID-COMM-CLAWB ROUNDED                     <ATHA67> 160513 
 0968.00                                         = (WSAA-PAID-COMM               <ATHA67> 160513 
 0969.00                                         * WSAA-T8Z82)                   <ATHA67> 160513 
 0970.00                                         * WSAA-PARTS-PERC-WRK           <ATHA67> 160513 
 0971.00                                                                         <ATHA67> 160513 
 0972.00                COMPUTE WSAA-PAID-OVRCOM-CLAWB ROUNDED                   <ATHA67> 160513 
 0973.00                                         = (WSAA-PAID-OVRCOM             <ATHA67> 160513 
 0974.00                                         * WSAA-T8Z82)                   <ATHA67> 160513 
 0975.00                                         * WSAA-PARTS-PERC-WRK           <ATHA67> 160513 
 0976.00                                                                         <ATHA67> 160513 
 0977.00      ****      MOVE 'MCP2'             TO WSAA-CRTABLE          <ATHB87><ATHA67> 170824 
 0978.00                                                                         <ATHA67> 160513 
 0979.00                MOVE '01'                   TO WSAA-ZCLB-LIFE            <ATHA67> 160513 
 0980.00                MOVE '01'                   TO WSAA-ZCLB-COVERAGE        <ATHA67> 160513 
 0981.00                MOVE '00'                   TO WSAA-ZCLB-RIDER           <ATHA67> 160513 
 0982.00                MOVE '00'                   TO WSAA-ZCLB-RECODE          <ATHA67> 160513 
 0983.00                PERFORM X5000-FIND-MAIN-COVR                             <ATHB87> 170824 
 0984.00                                                                         <ATHB87> 170824 
 0985.00                PERFORM X3000-READ-ZCLBCOV                               <ATHA67> 160513 
 0986.00                PERFORM X3100-FIND-CLAWB-REMN-REGP                       <ATHA67> 160513 
 0987.00                                                                         <ATHA67> 160513 
 0988.00                PERFORM X1900-WRITE-ZCLB                                 <ATHA67> 160513 
 0989.00                                                                         <ATHA67> 160513 
 0990.00                PERFORM X1400-WRITE-LIFA-REGP                            <ATHA67> 160513 
 0991.00                PERFORM X2000-DUE-ACCOUNTINGS                            <ATHA67> 160513 
 0992.00                PERFORM X2100-COLL-ACCOUNTINGS                           <ATHA67> 160513 
 0993.00            END-PERFORM                                                  <ATHA67> 160513 
 0994.00            .                                                            <ATHA67> 160513 
 0995.00        2250C-EXIT.                                                      <ATHA67> 160513 
 0996.00            EXIT.                                                        <ATHA67> 160513 
 0997.00       /                                                                          151106 
 0998.00        2255-FIND-COMMISSIONS SECTION.                                            151106 
 0999.00       *********************************                                          151106 
 1000.00        2255-START.                                                               151106 
 1001.00            SET NOT-FIND-COMM           TO TRUE                                   151109 
 1002.00            MOVE SPACES                 TO WSAA-LAST-RLDGACCT                     151216 
 1003.00            MOVE SPACES                 TO WSAA-USED-RLDGACCT                     151216 
 1004.00            INITIALIZE ACMVREV-PARAMS                                             151106 
 1005.00            INITIALIZE ACMVREVREC-KEY-DATA     OF ACMVREV-PARAMS                  151106 
 1006.00            INITIALIZE ACMVREVREC-NON-KEY-DATA OF ACMVREV-PARAMS                  151106 
 1007.00                                                                                  151106 
 1008.00            MOVE ACMVBK3-RLDGCOY        TO ACMVREV-RLDGCOY                        151109 
 1009.00            MOVE ACMVBK3-RDOCNUM        TO ACMVREV-RDOCNUM                        151109 
 1010.00            MOVE ACMVBK3-TRANNO         TO ACMVREV-TRANNO                         151106 
 1011.00                                                                                  151106 
 1012.00            MOVE BEGN                   TO ACMVREV-FUNCTION                       151106 
 1013.00            PERFORM X800-ACMVREV-IO                                               151106 
 1014.00                                                                                  151106 
 1015.00            IF  ACMVREV-STATUZ           = ENDP                                   151106 
 1016.00                GO TO 2255-EXIT                                                   151118 
 1017.00            END-IF                                                                151106 
 1018.00                                                                                  151106 
 1019.00            PERFORM                                                               151106 
 1020.00              UNTIL ACMVREV-STATUZ       = ENDP                                   151106 
 1021.00       **     OR FIND-COMM                                               <ATHA67> 160513 
 1022.00                                                                                  151106 
 1023.00                 IF  ACMVREV-SACSCODE    = WSCC-LE                                151216 
 1024.00                 AND ACMVREV-SACSTYP     = WSCC-OC                                151216 
 1025.00                     MOVE ACMVREV-RLDGACCT                                        151216 
 1026.00                                        TO WSAA-LAST-RLDGACCT                     151216 
 1027.00                 END-IF                                                           151216 
 1028.00                                                                                  151216 
 1029.00                 IF  ACMVREV-SACSCODE    = WSCC-LE                                151215 
 1030.00                 AND ACMVREV-SACSTYP     = WSCC-OC                                151215 
 1031.00                 AND ACMVREV-RLDGACCT    = ACMVBK3-RLDGACCT                       151215 
 1032.00                     COMPUTE WSAA-PAID-OVRCOM = ACMVREV-ORIGAMT                   151215 
 1033.00                                            + WSAA-PAID-OVRCOM                    151215 
 1034.00                                                                         <ATHA67> 160513 
 1035.00                     ADD ACMVREV-ORIGAMT TO WSAA-ACMV-OVRAMT             <ATHA67> 160513 
 1036.00                                           (WSAA-ACMV-ARRAY-CNT)         <ATHA67> 160513 
 1037.00                     MOVE ACMVREV-RLDGACCT TO WSAA-USED-RLDGACCT                  151216 
 1038.00                 END-IF                                                           151215 
 1039.00                                                                                  151216 
 1040.00                 IF  ACMVREV-SACSCODE    = WSCC-LA                                151106 
 1041.00                 AND ACMVREV-SACSTYP     = WSCC-CP                                151106 
 1042.00                 AND WSAA-USED-RLDGACCT  = WSAA-LAST-RLDGACCT                     151216 
 1043.00                     MOVE ACMVREV-RLDGACCT TO WSAA-AGNTNUM                        151123 
 1044.00                     COMPUTE WSAA-PAID-COMM = ACMVREV-ORIGAMT                     151106 
 1045.00                                            + WSAA-PAID-COMM                      151106 
 1046.00                                                                         <ATHA67> 160513 
 1047.00                     ADD ACMVREV-ORIGAMT TO WSAA-ACMV-ZCOMMAMT           <ATHA67> 160513 
 1048.00                                           (WSAA-ACMV-ARRAY-CNT)         <ATHA67> 160513 
 1049.00                 END-IF                                                           151106 
 1050.00                                                                                  151106 
 1051.00       *         IF  ACMVREV-RLDGACCT    = ACMVBK3-RLDGACCT                       151216 
 1052.00       *         AND ACMVREV-SACSTYP     = ACMVBK3-SACSTYP                        151216 
 1053.00       *         AND ACMVREV-SACSCODE    = ACMVBK3-SACSCODE                       151216 
 1054.00       *         AND ACMVREV-ORIGAMT     = ACMVBK3-ORIGAMT                        151216 
 1055.00       *             SET FIND-COMM       TO TRUE                                  151216 
 1056.00       *        END-IF                                                            151216 
 1057.00                                                                                  151106 
 1058.00                                                                                  151106 
 1059.00              MOVE NEXTR                  TO ACMVREV-FUNCTION                     151106 
 1060.00              PERFORM X800-ACMVREV-IO                                             151106 
 1061.00            END-PERFORM                                                           151106 
 1062.00            .                                                                     151106 
 1063.00        2255-EXIT.                                                                151106 
 1064.00            EXIT.                                                                 151106 
 1065.00       /                                                                 <ATHA43> 160322 
 1066.00        2257-READ-ZTUD-REGP   SECTION.                                   <ATHA43> 160322 
 1067.00       *********************************                                 <ATHA43> 160322 
 1068.00        2257-START.                                                      <ATHA43> 160322 
 1069.00                                                                         <ATHA43> 160322 
 1070.00            INITIALIZE ZTUD-PARAMS                                       <ATHA43> 160322 
 1071.00            INITIALIZE ZTUDREC-KEY-DATA     OF ZTUD-PARAMS               <ATHA43> 160322 
 1072.00            INITIALIZE ZTUDREC-NON-KEY-DATA OF ZTUD-PARAMS               <ATHA43> 160322 
 1073.00            MOVE O-K                    TO ZTUD-STATUZ                   <ATHA43> 160322 
 1074.00            MOVE ZSCLABCK-CHDRCOY       TO ZTUD-CHDRCOY                  <ATHA43> 160322 
 1075.00            MOVE ZSCLABCK-CHDRNUM       TO ZTUD-CHDRNUM                  <ATHA43> 160322 
 1076.00            MOVE BEGN                   TO ZTUD-FUNCTION                 <ATHA43> 160322 
 1077.00            MOVE ZTUDREC                TO ZTUD-FORMAT                   <ATHA43> 160322 
 1078.00                                                                         <ATHA43> 160322 
 1079.00            MOVE ZEROS                  TO WSAA-ZTUD-ARRAY-CNT           <ATHA43> 160322 
 1080.00            INITIALIZE WSAA-ZTUD-ARRAY                                   <ATHA43> 160322 
 1081.00            PERFORM X200-ZTUD-IO                                         <ATHA43> 160322 
 1082.00            PERFORM                                                      <ATHA43> 160322 
 1083.00               UNTIL ZTUD-STATUZ         = ENDP                          <ATHA43> 160322 
 1084.00                                                                         <ATHA43> 160322 
 1085.00                  IF  ZTUD-RECODE     = '00'                             <ATHA43> 160322 
 1086.00                  AND ZTUD-TRANS-CODE                                    <ATHA43> 160322 
 1087.00                                     NOT = 'REE1'                        <ATHA43> 160322 
 1088.00                      PERFORM 2257A-LOAD-ARRAY-REGP                      <ATHA43> 160323 
 1089.00                  END-IF                                                 <ATHA43> 160322 
 1090.00                                                                         <ATHA43> 160322 
 1091.00               MOVE NEXTR               TO ZTUD-FUNCTION                 <ATHA43> 160322 
 1092.00               PERFORM X200-ZTUD-IO                                      <ATHA43> 160322 
 1093.00            END-PERFORM                                                  <ATHA43> 160322 
 1094.00                                                                         <ATHA43> 160323 
 1095.00            PERFORM 2257B-READ-ZTUD-ARRAY                                <ATHA43> 160323 
 1096.00                                                                         <ATHA43> 160322 
 1097.00            .                                                            <ATHA43> 160322 
 1098.00        2257-EXIT.                                                       <ATHA43> 160322 
 1099.00            EXIT.                                                        <ATHA43> 160322 
 1100.00       /                                                                 <ATHA43> 160322 
 1101.00        2257A-LOAD-ARRAY-REGP SECTION.                                   <ATHA43> 160322 
 1102.00       *********************************                                 <ATHA43> 160322 
 1103.00        2257A-START.                                                     <ATHA43> 160322 
 1104.00                                                                         <ATHA43> 160322 
 1105.00            SET  NOT-ARRAY-CRTABLE-FOUND                                 <ATHA43> 160322 
 1106.00                                        TO TRUE                          <ATHA43> 160322 
 1107.00                                                                         <ATHA43> 160322 
 1108.00            PERFORM VARYING WSAA-IND1 FROM 1 BY 1                        <ATHA43> 160322 
 1109.00              UNTIL WSAA-IND1            > WSCC-MAX-ARRAY                <ATHA43> 160322 
 1110.00              OR    WSAA-ZTUD-RECODE  (WSAA-IND1)                        <ATHA43> 160322 
 1111.00                                         = SPACES                        <ATHA43> 160322 
 1112.00              OR    ARRAY-CRTABLE-FOUND                                  <ATHA43> 160322 
 1113.00                IF  ZTUD-RECODE                                          <ATHA43> 160322 
 1114.00                                         = WSAA-ZTUD-RECODE (WSAA-IND1)  <ATHA43> 160322 
 1115.00                    SET ARRAY-CRTABLE-FOUND                              <ATHA43> 160322 
 1116.00                                        TO TRUE                          <ATHA43> 160322 
 1117.00                    ADD ZTUD-ZPREMAMT   TO WSAA-ZTUD-ZPREMAMT            <ATHA43> 160322 
 1118.00                                           (WSAA-IND1)                   <ATHA43> 160322 
 1119.00                    ADD ZTUD-ZCOMMAMT   TO WSAA-ZTUD-ZCOMMAMT            <ATHA43> 160322 
 1120.00                                           (WSAA-IND1)                   <ATHA43> 160322 
 1121.00                    ADD ZTUD-NET        TO WSAA-ZTUD-NET                 <ATHA43> 160322 
 1122.00                                           (WSAA-IND1)                   <ATHA43> 160322 
 1123.00                END-IF                                                   <ATHA43> 160322 
 1124.00                MOVE WSAA-IND1          TO WSAA-ZTUD-ARRAY-CNT           <ATHA43> 160322 
 1125.00            END-PERFORM                                                  <ATHA43> 160322 
 1126.00                                                                         <ATHA43> 160322 
 1127.00            IF  ARRAY-CRTABLE-FOUND                                      <ATHA43> 160322 
 1128.00                GO TO 2257A-EXIT                                         <ATHA43> 160322 
 1129.00            END-IF                                                       <ATHA43> 160322 
 1130.00                                                                         <ATHA43> 160322 
 1131.00            ADD WSCC-NUM-1              TO WSAA-ZTUD-ARRAY-CNT           <ATHA43> 160322 
 1132.00            MOVE ZTUD-RECODE            TO WSAA-ZTUD-RECODE              <ATHA43> 160322 
 1133.00                                           (WSAA-ZTUD-ARRAY-CNT)         <ATHA43> 160322 
 1134.00            MOVE ZTUD-EFFDATE           TO WSAA-ZTUD-EFFDATE             <ATHA43> 160322 
 1135.00                                           (WSAA-ZTUD-ARRAY-CNT)         <ATHA43> 160322 
 1136.00            MOVE ZTUD-ZPREMAMT          TO WSAA-ZTUD-ZPREMAMT            <ATHA43> 160322 
 1137.00                                           (WSAA-ZTUD-ARRAY-CNT)         <ATHA43> 160322 
 1138.00            MOVE ZTUD-ZCOMMAMT          TO WSAA-ZTUD-ZCOMMAMT            <ATHA43> 160322 
 1139.00                                           (WSAA-ZTUD-ARRAY-CNT)         <ATHA43> 160322 
 1140.00            MOVE ZTUD-NET               TO WSAA-ZTUD-NET                 <ATHA43> 160322 
 1141.00                                           (WSAA-ZTUD-ARRAY-CNT)         <ATHA43> 160322 
 1142.00            MOVE ZTUD-JCOVCODE          TO WSAA-ZTUD-JCOVCODE            <ATHA43> 160322 
 1143.00                                           (WSAA-ZTUD-ARRAY-CNT)         <ATHA43> 160322 
 1144.00            MOVE ZTUD-LIFENUM           TO WSAA-ZTUD-LIFENUM             <ATHA43> 160322 
 1145.00                                           (WSAA-ZTUD-ARRAY-CNT)         <ATHA43> 160322 
 1146.00            MOVE ZTUD-AGNTNUM           TO WSAA-ZTUD-AGNTNUM             <ATHA43> 160322 
 1147.00                                           (WSAA-ZTUD-ARRAY-CNT)         <ATHA43> 160322 
 1148.00            MOVE ZTUD-ZCLNTAGN          TO WSAA-ZTUD-ZCLNTAGN            <ATHA43> 160322 
 1149.00                                           (WSAA-ZTUD-ARRAY-CNT)         <ATHA43> 160322 
 1150.00            MOVE ZTUD-ZCLNTUNI          TO WSAA-ZTUD-ZCLNTUNI            <ATHA43> 160322 
 1151.00                                           (WSAA-ZTUD-ARRAY-CNT)         <ATHA43> 160322 
 1152.00            MOVE ZTUD-ZCLNTASS          TO WSAA-ZTUD-ZCLNTASS            <ATHA43> 160322 
 1153.00                                           (WSAA-ZTUD-ARRAY-CNT)         <ATHA43> 160322 
 1154.00            MOVE ZTUD-ZCLNTAGY          TO WSAA-ZTUD-ZCLNTAGY            <ATHA43> 160322 
 1155.00                                           (WSAA-ZTUD-ARRAY-CNT)         <ATHA43> 160322 
 1156.00            .                                                            <ATHA43> 160322 
 1157.00        2257A-EXIT.                                                      <ATHA43> 160322 
 1158.00            EXIT.                                                        <ATHA43> 160322 
 1159.00       /                                                                 <ATHA43> 160322 
 1160.00        2257B-READ-ZTUD-ARRAY SECTION.                                   <ATHA43> 160322 
 1161.00       ****************************                                      <ATHA43> 160322 
 1162.00        2257B-START.                                                     <ATHA43> 160322 
 1163.00                                                                         <ATHA43> 160322 
 1164.00            MOVE ZEROS                  TO WSAA-PAID-PREM                <ATHA43> 160322 
 1165.00            MOVE ZEROS                  TO WSAA-PAID-COMM                <ATHA43> 160322 
 1166.00            MOVE ZEROS                  TO WSAA-PAID-OVRCOM              <ATHA43> 160322 
 1167.00            PERFORM VARYING WSAA-IND1 FROM 1 BY 1                        <ATHA43> 160322 
 1168.00               UNTIL WSAA-ZTUD-RECODE(WSAA-IND1)                         <ATHA43> 160322 
 1169.00                                         = SPACES                        <ATHA43> 160322 
 1170.00                 OR  WSAA-IND1           > WSAA-ZTUD-ARRAY-CNT           <ATHA43> 160322 
 1171.00                                                                         <ATHA43> 160322 
 1172.00                                                                         <ATHA43> 160322 
 1173.00                  IF WSAA-ZTUD-ZPREMAMT(WSAA-IND1)                       <ATHA43> 160322 
 1174.00                                     NOT = ZEROS                         <ATHA43> 160322 
 1175.00                     MOVE WSAA-ZTUD-EFFDATE(WSAA-IND1)                   <ATHA43> 160322 
 1176.00                                        TO WSAA-FROM-DATE                <ATHB37> 170208 
 1177.00                     MOVE WSAA-ZTUD-JCOVCODE(WSAA-IND1)                  <ATHA43> 160322 
 1178.00                                         TO WSAA-CRTABLE                 <ATHB37> 170208 
 1179.00                                                                         <ATHA43> 160322 
 1180.00                     PERFORM 2287-UPDATE-ZTUH-SURF                       <ATHA43> 160322 
 1181.00                     PERFORM 2285-WRITE-ZTUD-SURF                        <ATHA43> 160322 
 1182.00                  END-IF                                                 <ATHA43> 160322 
 1183.00                                                                         <ATHA43> 160322 
 1184.00            END-PERFORM                                                  <ATHA43> 160322 
 1185.00            .                                                            <ATHA43> 160322 
 1186.00        2257B-EXIT.                                                      <ATHA43> 160322 
 1187.00            EXIT.                                                        <ATHA43> 160322 
 1188.00       /                                                                          151030 
 1189.00        2270-READ-ZTUD-TOPUP  SECTION.                                            151030 
 1190.00       *********************************                                          151030 
 1191.00        2270-START.                                                               151030 
 1192.00            MOVE ZSCLABCK-CHDRNUM       TO WSAA-ACMV-CHDRNUM                      151118 
 1193.00       ***  MOVE '01'                   TO WSAA-ACMV-LIFE                <ATHB45> 170313 
 1194.00       ***  MOVE '02'                   TO WSAA-ACMV-COVERAGE            <ATHB45> 170313 
 1195.00       ***  MOVE '00'                   TO WSAA-ACMV-RIDER               <ATHB45> 170313 
 1196.00            MOVE WSAA-TU-LIFE           TO WSAA-ACMV-LIFE                <ATHB45> 170313 
 1197.00            MOVE WSAA-TU-COVERAGE       TO WSAA-ACMV-COVERAGE            <ATHB45> 170313 
 1198.00            MOVE WSAA-TU-RIDER          TO WSAA-ACMV-RIDER               <ATHB45> 170313 
 1199.00            MOVE '00'                   TO WSAA-ACMV-PLAN-SUFF                    151118 
 1200.00                                                                                  151030 
 1201.00            INITIALIZE ZTUD-PARAMS                                                151030 
 1202.00            INITIALIZE ZTUDREC-KEY-DATA     OF ZTUD-PARAMS                        151030 
 1203.00            INITIALIZE ZTUDREC-NON-KEY-DATA OF ZTUD-PARAMS                        151030 
 1204.00            MOVE O-K                    TO ZTUD-STATUZ                            151030 
 1205.00            MOVE ZSCLABCK-CHDRCOY       TO ZTUD-CHDRCOY                           151030 
 1206.00            MOVE ZSCLABCK-CHDRNUM       TO ZTUD-CHDRNUM                           151030 
 1207.00            MOVE BEGN                   TO ZTUD-FUNCTION                          151030 
 1208.00            MOVE ZTUDREC                TO ZTUD-FORMAT                            151030 
 1209.00                                                                                  151030 
 1210.00            MOVE ZEROS                  TO WSAA-ZTUD-ARRAY-CNT                    151103 
 1211.00            MOVE ZEROS                  TO WSAA-OVRAMT-TOPUP                      151118 
 1212.00            INITIALIZE WSAA-ZTUD-ARRAY                                   <ATHA43> 160323 
 1213.00            PERFORM X200-ZTUD-IO                                                  151030 
 1214.00            PERFORM                                                               151030 
 1215.00               UNTIL ZTUD-STATUZ         = ENDP                                   151030 
 1216.00                                                                         <ATHD11> 181018 
 1217.00                  IF   CLAWBACK-COVER                                    <ATHD11> 181018 
 1218.00                  AND  ZSCLABCK-CRTABLE NOT = ZTUD-JCOVCODE              <ATHD11> 181022 
 1219.00                       CONTINUE                                          <ATHD11> 181022 
 1220.00                  ELSE                                                   <ATHD11> 181018 
 1221.00                      PERFORM 2275A-FIND-OVRCOM-TOPUP                             181018 
 1222.00                                                                         <ATHD11> 181018 
 1223.00                      IF  ZTUD-TRANS-CODE           = 'T679'             <ATHA67> 181018 
 1224.00                      AND ZTUD-TRANNOR              = ZEROS              <ATHA67> 181018 
 1225.00       ***            IF  ZTUD-TRANS-CODE NOT = WSCC-REE1        <ATHA67><ATHA43> 181018 
 1226.00       ***            AND ZTUD-RECODE     NOT = '00'             <ATHA67><ATHA43> 181018 
 1227.00                          PERFORM 2275-LOAD-ARRAY                                 181018 
 1228.00       ***            END-IF                                     <ATHA67><ATHA43> 181018 
 1229.00                      END-IF                                             <ATHA67> 181018 
 1230.00                  END-IF                                                 <ATHD11> 181018 
 1231.00                                                                                  151030 
 1232.00               MOVE NEXTR               TO ZTUD-FUNCTION                          151030 
 1233.00               PERFORM X200-ZTUD-IO                                               151030 
 1234.00            END-PERFORM                                                           151030 
 1235.00                                                                                  151108 
 1236.00            .                                                                     151030 
 1237.00        2270-EXIT.                                                                151030 
 1238.00            EXIT.                                                                 151030 
 1239.00       /                                                                          151030 
 1240.00        2275-LOAD-ARRAY SECTION.                                                  151030 
 1241.00       *********************************                                          151030 
 1242.00        2275-START.                                                               151030 
 1243.00                                                                                  151030 
 1244.00            SET  NOT-ARRAY-CRTABLE-FOUND                                          151108 
 1245.00                                        TO TRUE                                   151108 
 1246.00                                                                                  151108 
 1247.00            PERFORM VARYING WSAA-IND1 FROM 1 BY 1                                 151030 
 1248.00              UNTIL WSAA-IND1            > WSCC-MAX-ARRAY                         151030 
 1249.00              OR    WSAA-ZTUD-RECODE  (WSAA-IND1)                                 151108 
 1250.00                                         = SPACES                                 151030 
 1251.00              OR    ARRAY-CRTABLE-FOUND                                           151030 
 1252.00                IF  ZTUD-RECODE                                                   151030 
 1253.00                                         = WSAA-ZTUD-RECODE (WSAA-IND1)           151030 
 1254.00                    SET ARRAY-CRTABLE-FOUND                                       151030 
 1255.00                                        TO TRUE                                   151030 
 1256.00                    ADD ZTUD-ZPREMAMT   TO WSAA-ZTUD-ZPREMAMT                     151108 
 1257.00                                           (WSAA-IND1)                            151109 
 1258.00                    ADD ZTUD-ZCOMMAMT   TO WSAA-ZTUD-ZCOMMAMT                     151108 
 1259.00                                           (WSAA-IND1)                            151030 
 1260.00                    ADD ZTUD-NET        TO WSAA-ZTUD-NET                          151108 
 1261.00                                           (WSAA-IND1)                            151108 
 1262.00                    ADD WSAA-OVRAMT-TOPUP  TO WSAA-ZTUD-OVRAMT                    151118 
 1263.00                                           (WSAA-IND1)                            151118 
 1264.00                END-IF                                                            151030 
 1265.00                MOVE WSAA-IND1          TO WSAA-ZTUD-ARRAY-CNT                    151030 
 1266.00            END-PERFORM                                                           151030 
 1267.00                                                                                  151030 
 1268.00            IF  ARRAY-CRTABLE-FOUND                                               151030 
 1269.00                GO TO 2275-EXIT                                                   151030 
 1270.00            END-IF                                                                151030 
 1271.00                                                                                  151030 
 1272.00            ADD WSCC-NUM-1              TO WSAA-ZTUD-ARRAY-CNT                    151030 
 1273.00            MOVE ZTUD-RECODE            TO WSAA-ZTUD-RECODE                       151030 
 1274.00                                           (WSAA-ZTUD-ARRAY-CNT)                  151030 
 1275.00            MOVE ZTUD-EFFDATE           TO WSAA-ZTUD-EFFDATE                      151109 
 1276.00                                           (WSAA-ZTUD-ARRAY-CNT)                  151108 
 1277.00            MOVE ZTUD-ZPREMAMT          TO WSAA-ZTUD-ZPREMAMT                     151108 
 1278.00                                           (WSAA-ZTUD-ARRAY-CNT)                  151108 
 1279.00            MOVE ZTUD-ZCOMMAMT          TO WSAA-ZTUD-ZCOMMAMT                     151108 
 1280.00                                           (WSAA-ZTUD-ARRAY-CNT)                  151108 
 1281.00            MOVE ZTUD-NET               TO WSAA-ZTUD-NET                          151108 
 1282.00                                           (WSAA-ZTUD-ARRAY-CNT)                  151108 
 1283.00            MOVE WSAA-OVRAMT-TOPUP      TO WSAA-ZTUD-OVRAMT                       151118 
 1284.00                                           (WSAA-ZTUD-ARRAY-CNT)                  151118 
 1285.00            MOVE ZTUD-JCOVCODE          TO WSAA-ZTUD-JCOVCODE                     151108 
 1286.00                                           (WSAA-ZTUD-ARRAY-CNT)                  151108 
 1287.00            MOVE ZTUD-LIFENUM           TO WSAA-ZTUD-LIFENUM                      151108 
 1288.00                                           (WSAA-ZTUD-ARRAY-CNT)                  151108 
 1289.00            MOVE ZTUD-AGNTNUM           TO WSAA-ZTUD-AGNTNUM                      151108 
 1290.00                                           (WSAA-ZTUD-ARRAY-CNT)                  151108 
 1291.00            MOVE ZTUD-ZCLNTAGN          TO WSAA-ZTUD-ZCLNTAGN                     151108 
 1292.00                                           (WSAA-ZTUD-ARRAY-CNT)                  151108 
 1293.00            MOVE ZTUD-ZCLNTUNI          TO WSAA-ZTUD-ZCLNTUNI                     151108 
 1294.00                                           (WSAA-ZTUD-ARRAY-CNT)                  151108 
 1295.00            MOVE ZTUD-ZCLNTASS          TO WSAA-ZTUD-ZCLNTASS                     151108 
 1296.00                                           (WSAA-ZTUD-ARRAY-CNT)                  151108 
 1297.00            MOVE ZTUD-ZCLNTAGY          TO WSAA-ZTUD-ZCLNTAGY                     151108 
 1298.00                                           (WSAA-ZTUD-ARRAY-CNT)                  151108 
 1299.00            .                                                                     151030 
 1300.00        2275-EXIT.                                                                151030 
 1301.00            EXIT.                                                                 151030 
 1302.00       /                                                                          151110 
 1303.00        2280-READ-ZTUD-ARRAY SECTION.                                             151110 
 1304.00       ****************************                                               151110 
 1305.00        2280-START.                                                               151110 
 1306.00                                                                                  151110 
 1307.00       **   MOVE ZEROS                  TO WSAA-PAID-PREM                <ATHA67> 160404 
 1308.00       **   MOVE ZEROS                  TO WSAA-PAID-COMM                <ATHA67> 160404 
 1309.00       **   MOVE ZEROS                  TO WSAA-PAID-OVRCOM              <ATHA67> 160404 
 1310.00            PERFORM VARYING WSAA-IND1 FROM 1 BY 1                                 151110 
 1311.00               UNTIL WSAA-ZTUD-RECODE(WSAA-IND1)                                  151110 
 1312.00                                         = SPACES                                 151110 
 1313.00                 OR  WSAA-IND1           > WSAA-ZTUD-ARRAY-CNT                    151110 
 1314.00                                                                                  151110 
 1315.00                  MOVE ZEROS            TO WSAA-CLAWBACK-TOPUP                    151110 
 1316.00                  MOVE ZEROS            TO WSAA-CLAWBACK-NET                      151114 
 1317.00                  MOVE ZEROS            TO WSAA-CLAWBACK-OVRAMT                   151118 
 1318.00                  MOVE ZEROS            TO WSAA-PAID-PREM                <ATHA67> 160404 
 1319.00                  MOVE ZEROS            TO WSAA-PAID-COMM                <ATHA67> 160404 
 1320.00                  MOVE ZEROS            TO WSAA-PAID-OVRCOM              <ATHA67> 160404 
 1321.00                                                                                  151110 
 1322.00                  IF WSAA-ZTUD-ZPREMAMT(WSAA-IND1)                                151110 
 1323.00                                     NOT = ZEROS                                  151110 
 1324.00                     MOVE WSAA-ZTUD-EFFDATE(WSAA-IND1)                            151110 
 1325.00                                        TO WSAA-FROM-DATE                         151110 
 1326.00                                                                         <ATHA67> 160414 
 1327.00       * DO NOT CHECK AGENT WHEN CFI GENIUS PLUS                         <ATHA67> 160414 
 1328.00                     IF NOT-CHECK-AGENT                                  <ATHA67> 160414 
 1329.00                        PERFORM 2280A-FIND-CLAWB-TOPUP                   <ATHA67> 160414 
 1330.00                     ELSE                                                <ATHA67> 160414 
 1331.00       *** ELSE CHECK AGENT                                              <ATHA67> 160414 
 1332.00                     IF WSAA-ZTUD-ZCLNTAGN(WSAA-IND1)                             151110 
 1333.00                                         = WSAA-ZCHA-CLNTNUM                      151110 
 1334.00                        PERFORM 2280A-FIND-CLAWB-TOPUP                   <ATHA67> 160414 
 1335.00                     END-IF                                                       151110 
 1336.00                     END-IF                                              <ATHA67> 160414 
 1337.00       *********                                                                  151214 
 1338.00       ***           MOVE '01'          TO WSAA-ZCLB-LIFE        <ATHB45><ATHA67> 170313 
 1339.00       ***           MOVE '02'          TO WSAA-ZCLB-COVERAGE    <ATHB45><ATHA67> 170313 
 1340.00       ***           MOVE '00'          TO WSAA-ZCLB-RIDER       <ATHB45><ATHA67> 170313 
 1341.00                                                                         <ATHB87> 170824 
 1342.00       * FIND THE COVERAGE CODE BY READING ZCOVCRT               <ATHB87><ATHB45> 170824 
 1343.00                     MOVE WSAA-ZTUD-JCOVCODE(WSAA-IND1)                  <ATHB87> 170824 
 1344.00                                        TO WSAA-TU-CRTABLE               <ATHB87> 170824 
 1345.00                     PERFORM X4800-READ-ZCOVCRT                          <ATHB87> 170824 
 1346.00       ****                                                              <ATHB87> 170824 
 1347.00                     MOVE WSAA-TU-LIFE  TO WSAA-ZCLB-LIFE                <ATHB45> 170313 
 1348.00                     MOVE WSAA-TU-COVERAGE                               <ATHB45> 170313 
 1349.00                                        TO WSAA-ZCLB-COVERAGE            <ATHB45> 170313 
 1350.00                     MOVE WSAA-TU-RIDER TO WSAA-ZCLB-RIDER               <ATHB45> 170313 
 1351.00                                                                         <ATHB45> 170313 
 1352.00                     MOVE WSAA-ZTUD-RECODE(WSAA-IND1)                    <ATHA67> 160406 
 1353.00                                         TO WSAA-ZCLB-RECODE             <ATHA67> 160406 
 1354.00                     PERFORM X3000-READ-ZCLBCOV                          <ATHA67> 160404 
 1355.00                     PERFORM X3200-FIND-CLAWB-REMN-TOPUP                 <ATHA67> 160404 
 1356.00                     PERFORM 2295-WRITE-LIFA-TOPUP                       <ATHA67> 160404 
 1357.00       *********                                                                  151214 
 1358.00       ***           COMPUTE WSAA-TOT-CLAWB-TOPUP                        <ATHA67> 160404 
 1359.00       ***                               = WSAA-CLAWBACK-TOPUP           <ATHA67> 160404 
 1360.00       ***                               + WSAA-TOT-CLAWB-TOPUP          <ATHA67> 160404 
 1361.00       ***           COMPUTE WSAA-TOT-CLAWB-NET                          <ATHA67> 160404 
 1362.00       ***                               = WSAA-CLAWBACK-NET             <ATHA67> 160404 
 1363.00       ***                               + WSAA-TOT-CLAWB-NET            <ATHA67> 160404 
 1364.00       ***           COMPUTE WSAA-TOT-CLAWB-OVRAMT                       <ATHA67> 160404 
 1365.00       ***                               = WSAA-CLAWBACK-OVRAMT          <ATHA67> 160404 
 1366.00       ***                               + WSAA-TOT-CLAWB-OVRAMT         <ATHA67> 160404 
 1367.00       ***           MOVE WSAA-ZTUD-JCOVCODE(WSAA-IND1)                  <ATHA67> 160404 
 1368.00       ***                               TO WSAA-CRTABLE                 <ATHA67> 160404 
 1369.00                                                                                  151110 
 1370.00                     PERFORM 2287-UPDATE-ZTUH-SURF                                151110 
 1371.00                     PERFORM 2285-WRITE-ZTUD-SURF                                 151110 
 1372.00                  END-IF                                                          151110 
 1373.00                                                                                  151110 
 1374.00            END-PERFORM                                                           151110 
 1375.00            .                                                                     151110 
 1376.00        2280-EXIT.                                                                151110 
 1377.00            EXIT.                                                                 151110 
 1378.00       /                                                                          151118 
 1379.00        2275A-FIND-OVRCOM-TOPUP SECTION.                                          151118 
 1380.00       *********************************                                          151118 
 1381.00        2275A-START.                                                              151118 
 1382.00            MOVE ZEROS                        TO WSAA-OVRAMT-TOPUP                151118 
 1383.00            IF  ZTUD-TRANS-CODE       NOT = 'T679'                                151118 
 1384.00            OR  (ZTUD-TRANS-CODE           = 'T679'                               151124 
 1385.00            AND ZTUD-TRANNOR          NOT = ZEROS)                                151124 
 1386.00                GO TO 2275A-EXIT                                                  151118 
 1387.00            END-IF                                                                151118 
 1388.00            MOVE ZTUD-JCOVCODE          TO WSAA-TU-CRTABLE               <ATHB87> 170824 
 1389.00            PERFORM X4800-READ-ZCOVCRT                                   <ATHB87> 170824 
 1390.00            MOVE WSAA-TU-LIFE           TO WSAA-ACMV-LIFE                <ATHB87> 170824 
 1391.00            MOVE WSAA-TU-COVERAGE       TO WSAA-ACMV-COVERAGE            <ATHB87> 170824 
 1392.00            MOVE WSAA-TU-RIDER          TO WSAA-ACMV-RIDER               <ATHB87> 170824 
 1393.00            MOVE '00'                   TO WSAA-ACMV-PLAN-SUFF           <ATHB87> 170824 
 1394.00                                                                         <ATHB87> 170824 
 1395.00            INITIALIZE ACMVREV-PARAMS                                             151118 
 1396.00            INITIALIZE ACMVREVREC-KEY-DATA     OF ACMVREV-PARAMS                  151118 
 1397.00            INITIALIZE ACMVREVREC-NON-KEY-DATA OF ACMVREV-PARAMS                  151118 
 1398.00                                                                                  151118 
 1399.00            MOVE ZTUD-CHDRCOY           TO ACMVREV-RLDGCOY                        151118 
 1400.00            MOVE ZTUD-CHDRNUM           TO ACMVREV-RDOCNUM                        151118 
 1401.00            MOVE ZTUD-TRANNO            TO ACMVREV-TRANNO                         151118 
 1402.00                                                                                  151118 
 1403.00            MOVE BEGN                   TO ACMVREV-FUNCTION                       151118 
 1404.00            PERFORM X800A-ACMVREV-IO                                              151118 
 1405.00                                                                                  151118 
 1406.00            IF  ACMVREV-STATUZ           = ENDP                                   151118 
 1407.00                GO TO 2275A-EXIT                                                  151118 
 1408.00            END-IF                                                                151118 
 1409.00                                                                                  151118 
 1410.00            PERFORM                                                               151118 
 1411.00              UNTIL ACMVREV-STATUZ       = ENDP                                   151118 
 1412.00                                                                                  151118 
 1413.00                 IF  ACMVREV-SACSCODE    = WSAA-T5645-SACSCODE(1)                 151118 
 1414.00                 AND ACMVREV-SACSTYP     = WSAA-T5645-SACSTYPE(1)                 151118 
 1415.00                 AND ACMVREV-RLDGACCT    = WSAA-ACMV-RLDGACCT                     151118 
 1416.00                     COMPUTE WSAA-OVRAMT-TOPUP = ACMVREV-ORIGAMT                  151118 
 1417.00                                             + WSAA-OVRAMT-TOPUP                  151118 
 1418.00                 END-IF                                                           151118 
 1419.00                                                                                  151118 
 1420.00              MOVE NEXTR                  TO ACMVREV-FUNCTION                     151118 
 1421.00              PERFORM X800A-ACMVREV-IO                                            151118 
 1422.00            END-PERFORM                                                           151118 
 1423.00            .                                                                     151118 
 1424.00        2275A-EXIT.                                                               151118 
 1425.00            EXIT.                                                                 151118 
 1426.00       /                                                                 <ATHA67> 160414 
 1427.00        2280A-FIND-CLAWB-TOPUP SECTION.                                  <ATHA67> 160414 
 1428.00       *********************************                                 <ATHA67> 160414 
 1429.00        2280A-START.                                                     <ATHA67> 160414 
 1430.00                        MOVE WSAA-ZTUD-AGNTNUM(WSAA-IND1)                <ATHA67> 160414 
 1431.00                                        TO WSAA-AGNTNUM                  <ATHA67> 160414 
 1432.00                        PERFORM X900A-CLAWBACK-RULES-PERC-TOP            <ATHA67> 160414 
 1433.00                                                                         <ATHA67> 160414 
 1434.00                        COMPUTE WSAA-CLAWBACK-TOPUP ROUNDED              <ATHA67> 160414 
 1435.00                                         = WSAA-T8Z82                    <ATHA67> 160414 
 1436.00                                         * WSAA-ZTUD-ZCOMMAMT(WSAA-IND1) <ATHA67> 160414 
 1437.00                                         * WSAA-PARTS-PERC-WRK           <ATHA67> 160414 
 1438.00                        END-COMPUTE                                      <ATHA67> 160414 
 1439.00                                                                         <ATHA67> 160414 
 1440.00                        COMPUTE WSAA-CLAWBACK-NET   ROUNDED              <ATHA67> 160414 
 1441.00                                         = WSAA-T8Z82                    <ATHA67> 160414 
 1442.00                                         * WSAA-ZTUD-NET(WSAA-IND1)      <ATHA67> 160414 
 1443.00                                         * WSAA-PARTS-PERC-WRK           <ATHA67> 160414 
 1444.00                        END-COMPUTE                                      <ATHA67> 160414 
 1445.00                                                                         <ATHA67> 160414 
 1446.00                        COMPUTE WSAA-CLAWBACK-OVRAMT   ROUNDED           <ATHA67> 160414 
 1447.00                                         = WSAA-T8Z82                    <ATHA67> 160414 
 1448.00                                         * WSAA-ZTUD-OVRAMT(WSAA-IND1)   <ATHA67> 160414 
 1449.00                                         * WSAA-PARTS-PERC-WRK           <ATHA67> 160414 
 1450.00                        END-COMPUTE                                      <ATHA67> 160414 
 1451.00                                                                         <ATHA67> 160414 
 1452.00                        COMPUTE WSAA-PAID-PREM                           <ATHA67> 160414 
 1453.00                                         = WSAA-ZTUD-NET(WSAA-IND1)      <ATHA67> 160414 
 1454.00                                         + WSAA-PAID-PREM                <ATHA67> 160414 
 1455.00                        COMPUTE WSAA-PAID-COMM                           <ATHA67> 160414 
 1456.00                                         = WSAA-ZTUD-ZCOMMAMT(WSAA-IND1) <ATHA67> 160414 
 1457.00                                         + WSAA-PAID-COMM                <ATHA67> 160414 
 1458.00                        COMPUTE WSAA-PAID-OVRCOM                         <ATHA67> 160414 
 1459.00                                         = WSAA-ZTUD-OVRAMT(WSAA-IND1)   <ATHA67> 160414 
 1460.00                                         + WSAA-PAID-OVRCOM              <ATHA67> 160414 
 1461.00            .                                                            <ATHA67> 160414 
 1462.00        2280A-EXIT.                                                      <ATHA67> 160414 
 1463.00            EXIT.                                                        <ATHA67> 160414 
 1464.00       /                                                                          151110 
 1465.00        2285-WRITE-ZTUD-SURF SECTION.                                             151110 
 1466.00       *********************************                                          151110 
 1467.00        2285-START.                                                               151110 
 1468.00                                                                                  151110 
 1469.00            INITIALIZE ZTUD-PARAMS                                                151110 
 1470.00            INITIALIZE ZTUDREC-KEY-DATA     OF ZTUD-PARAMS                        151110 
 1471.00            INITIALIZE ZTUDREC-NON-KEY-DATA OF ZTUD-PARAMS                        151110 
 1472.00                                                                                  151110 
 1473.00            MOVE CHDRMJA-CHDRCOY        TO ZTUD-CHDRCOY                           151110 
 1474.00            MOVE CHDRMJA-CHDRNUM        TO ZTUD-CHDRNUM                           151110 
 1475.00            MOVE WSAA-ZTUD-RECODE(WSAA-IND1)                                      151110 
 1476.00                                        TO ZTUD-RECODE                            151110 
 1477.00            MOVE ZSCLABCK-TRANNO        TO ZTUD-TRANNO                            151110 
 1478.00            MOVE ZSCLABCK-EFFDATE       TO ZTUD-PRCDATE                           151110 
 1479.00            MOVE WSAA-ZTUD-EFFDATE(WSAA-IND1)                                     151110 
 1480.00                                        TO ZTUD-EFFDATE                           151110 
 1481.00            MOVE ZSCLABCK-BATCTRCDE     TO ZTUD-TRANS-CODE                        151110 
 1482.00                                                                         <ATHA43> 160323 
 1483.00            IF  ZSCLABCK-FUNCTION    NOT = WSCC-SURPS                    <ATHA43> 160323 
 1484.00            AND ZSCLABCK-FUNCTION    NOT = WSCC-SURGP                    <ATHC41> 180308 
 1485.00            COMPUTE ZTUD-ZPREMAMT        = WSAA-ZTUD-ZPREMAMT                     151110 
 1486.00                                           (WSAA-IND1)                            151110 
 1487.00                                         * WSCC-NUM--1                            151110 
 1488.00            END-COMPUTE                                                           151110 
 1489.00            END-IF                                                       <ATHA43> 160323 
 1490.00            IF  WSAA-ZTUD-RECODE(WSAA-IND1)   = '00'                     <ATHA43> 160323 
 1491.00            COMPUTE ZTUD-ZCOMMAMT        = WSAA-PAID-COMM-CLAWB          <ATHA43> 160323 
 1492.00                                         * WSCC-NUM--1                   <ATHA43> 160323 
 1493.00            END-COMPUTE                                                  <ATHA43> 160323 
 1494.00            COMPUTE ZTUD-NET             = WSAA-PAID-PREM-CLAWB          <ATHA43> 160323 
 1495.00                                         * WSCC-NUM--1                   <ATHA43> 160323 
 1496.00            END-COMPUTE                                                  <ATHA43> 160323 
 1497.00            ELSE                                                         <ATHA43> 160323 
 1498.00            COMPUTE ZTUD-ZCOMMAMT        = WSAA-CLAWBACK-TOPUP                    151110 
 1499.00                                         * WSCC-NUM--1                            151110 
 1500.00            END-COMPUTE                                                           151110 
 1501.00            COMPUTE ZTUD-NET             = WSAA-CLAWBACK-NET                      151110 
 1502.00                                         * WSCC-NUM--1                            151110 
 1503.00            END-COMPUTE                                                           151110 
 1504.00            END-IF                                                       <ATHA43> 160323 
 1505.00            MOVE WSAA-ZTUD-LIFENUM(WSAA-IND1)                                     151110 
 1506.00                                        TO ZTUD-LIFENUM                           151110 
 1507.00            MOVE WSAA-ZTUD-JCOVCODE(WSAA-IND1)                                    151110 
 1508.00                                        TO ZTUD-JCOVCODE                          151110 
 1509.00            MOVE WSAA-ZTUD-AGNTNUM(WSAA-IND1)                                     151110 
 1510.00                                        TO ZTUD-AGNTNUM                           151110 
 1511.00            MOVE WSAA-ZTUD-ZCLNTAGN(WSAA-IND1)                                    151110 
 1512.00                                        TO ZTUD-ZCLNTAGN                          151110 
 1513.00            MOVE WSAA-ZTUD-ZCLNTUNI(WSAA-IND1)                                    151110 
 1514.00                                        TO ZTUD-ZCLNTUNI                          151110 
 1515.00            MOVE WSAA-ZTUD-ZCLNTASS(WSAA-IND1)                                    151110 
 1516.00                                        TO ZTUD-ZCLNTASS                          151110 
 1517.00            MOVE WSAA-ZTUD-ZCLNTAGY(WSAA-IND1)                                    151110 
 1518.00                                        TO ZTUD-ZCLNTAGY                          151110 
 1519.00                                                                                  151110 
 1520.00            MOVE WSCC-TXT-1             TO ZTUD-VALIDFLAG                         151110 
 1521.00                                                                                  151110 
 1522.00            MOVE WRITR                  TO ZTUD-FUNCTION                          151110 
 1523.00            PERFORM X200-ZTUD-IO                                                  151110 
 1524.00            .                                                                     151110 
 1525.00        2285-EXIT.                                                                151110 
 1526.00            EXIT.                                                                 151110 
 1527.00       /                                                                          151110 
 1528.00        2287-UPDATE-ZTUH-SURF SECTION.                                            151110 
 1529.00       ******************************                                             151110 
 1530.00        2287-START.                                                               151110 
 1531.00                                                                                  151110 
 1532.00            INITIALIZE ZTUH-PARAMS                                                151110 
 1533.00            INITIALIZE ZTUHREC-KEY-DATA     OF ZTUH-PARAMS                        151110 
 1534.00            INITIALIZE ZTUHREC-NON-KEY-DATA OF ZTUH-PARAMS                        151110 
 1535.00                                                                                  151110 
 1536.00            MOVE ZSCLABCK-CHDRCOY      TO ZTUH-CHDRCOY                            151110 
 1537.00            MOVE ZSCLABCK-CHDRNUM      TO ZTUH-CHDRNUM                            151110 
 1538.00            MOVE WSAA-ZTUD-RECODE(WSAA-IND1)                                      151110 
 1539.00                                        TO ZTUH-RECODE                            151114 
 1540.00                                                                                  151110 
 1541.00            MOVE READR                  TO ZTUH-FUNCTION                          151114 
 1542.00            PERFORM X1250-ZTUH-IO                                                 151110 
 1543.00            IF  ZTUH-STATUZ       NOT = O-K                                       151110 
 1544.00                GO TO 2287-EXIT                                                   151110 
 1545.00            END-IF                                                                151110 
 1546.00                                                                                  151110 
 1547.00            MOVE READD                  TO ZTUH-FUNCTION                          151114 
 1548.00            PERFORM X1250-ZTUH-IO                                                 151114 
 1549.00                                                                                  151110 
 1550.00            MOVE WSCC-TXT-2             TO ZTUH-VALIDFLAG                         151110 
 1551.00            MOVE WRITD                  TO ZTUH-FUNCTION                          151114 
 1552.00            PERFORM X1250-ZTUH-IO                                                 151110 
 1553.00                                                                                  151110 
 1554.00            PERFORM X1270-WRITE-ZTUHTRN                                           151110 
 1555.00                                                                                  151110 
 1556.00            .                                                                     151110 
 1557.00        2287-EXIT.                                                                151110 
 1558.00            EXIT.                                                                 151110 
 1559.00       /                                                                          151112 
 1560.00        2290-WRITE-LIFA-TOPUP SECTION.                                            151112 
 1561.00       ****************************                                               151112 
 1562.00        2290-START.                                                               151112 
 1563.00                                                                                  151112 
 1564.00             IF WSAA-TOT-CLAWB-TOPUP    = ZEROS                                   151112 
 1565.00                GO TO 2290-EXIT                                                   151112 
 1566.00             END-IF                                                               151112 
 1567.00       *     COMPUTE WSAA-TOT-CLAWB-OVRAMT ROUNDED                                151118 
 1568.00       *                                     = WSAA-TOT-CLAWB-NET                 151118 
 1569.00       *                                     * (0.5 / 100)                        151118 
 1570.00                                                                                  151116 
 1571.00            PERFORM X2050-READ-AGLF                                               151123 
 1572.00            PERFORM X1400-WRITE-LIFA-REGP                                         151112 
 1573.00                                                                                  151112 
 1574.00            IF  WSAA-TOT-CLAWB-OVRAMT                                             151118 
 1575.00                                     NOT  = ZEROS                                 151118 
 1576.00                MOVE ZSCLABCK-CHDRNUM       TO WSAA-RLDG-CHDRNUM                  151112 
 1577.00       ***      MOVE '01'                   TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1578.00       ***      MOVE '02'                   TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1579.00       ***      MOVE '00'                   TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1580.00                MOVE WSAA-TU-LIFE           TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1581.00                MOVE WSAA-TU-COVERAGE       TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1582.00                MOVE WSAA-TU-RIDER          TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1583.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151112 
 1584.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151112 
 1585.00                                                                                  151113 
 1586.00       *        COMPUTE LIFA-ORIGAMT ROUNDED = WSAA-TOT-CLAWB-NET                 151118 
 1587.00       *                                     * (0.5 / 100)                        151118 
 1588.00       *                                     * WSCC-NUM--1                        151118 
 1589.00                                                                                  151116 
 1590.00                COMPUTE LIFA-ORIGAMT ROUNDED = WSAA-TOT-CLAWB-OVRAMT              151118 
 1591.00                                             * WSCC-NUM--1                        151118 
 1592.00                                                                                  151118 
 1593.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151112 
 1594.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151112 
 1595.00                MOVE 1                  TO IX-SA                                  151112 
 1596.00                PERFORM X1450-POST-COMM                                           151112 
 1597.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151112 
 1598.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151112 
 1599.00                MOVE 11                 TO IX-SA                                  151112 
 1600.00                PERFORM X1450-POST-COMM                                           151112 
 1601.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151112 
 1602.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151112 
 1603.00                MOVE 2                  TO IX-SA                                  151112 
 1604.00                PERFORM X1450-POST-COMM                                           151112 
 1605.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151112 
 1606.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151112 
 1607.00                MOVE 12                 TO IX-SA                                  151112 
 1608.00                PERFORM X1450-POST-COMM                                           151112 
 1609.00            END-IF                                                                151112 
 1610.00            IF  WSAA-TOT-CLAWB-TOPUP                                              151112 
 1611.00                                     NOT = ZEROS                                  151112 
 1612.00       **       MOVE WSAA-TOT-CLAWB-TOPUP                                         151113 
 1613.00       **                               TO LIFA-ORIGAMT                           151113 
 1614.00                COMPUTE LIFA-ORIGAMT         = WSAA-TOT-CLAWB-TOPUP               151113 
 1615.00                                             * WSCC-NUM--1                        151113 
 1616.00       ***      MOVE '01'                   TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1617.00       ***      MOVE '02'                   TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1618.00       ***      MOVE '00'                   TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1619.00                MOVE WSAA-TU-LIFE           TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1620.00                MOVE WSAA-TU-COVERAGE       TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1621.00                MOVE WSAA-TU-RIDER          TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1622.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151113 
 1623.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151113 
 1624.00                MOVE 4                  TO IX-SA                                  151112 
 1625.00                PERFORM X1450-POST-COMM                                           151112 
 1626.00                MOVE 8                  TO IX-SA                                  151112 
 1627.00                PERFORM X1450-POST-COMM                                           151112 
 1628.00                                                                                  151113 
 1629.00                MOVE SPACES             TO LIFA-RLDGACCT                          151113 
 1630.00                MOVE WSAA-AGNTNUM       TO LIFA-RLDGACCT                          151113 
 1631.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151113 
 1632.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151113 
 1633.00                MOVE 9                  TO IX-SA                                  151112 
 1634.00                PERFORM X1450-POST-COMM                                           151112 
 1635.00                                                                                  151113 
 1636.00       ***      MOVE '01'                   TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1637.00       ***      MOVE '02'                   TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1638.00       ***      MOVE '00'                   TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1639.00                MOVE WSAA-TU-LIFE           TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1640.00                MOVE WSAA-TU-COVERAGE       TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1641.00                MOVE WSAA-TU-RIDER          TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1642.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151113 
 1643.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151113 
 1644.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151113 
 1645.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151113 
 1646.00                MOVE 10                 TO IX-SA                                  151112 
 1647.00                PERFORM X1450-POST-COMM                                           151112 
 1648.00            END-IF                                                                151112 
 1649.00                                                                                  151113 
 1650.00            IF  WSAA-TOT-CLAWB-NET                                                151112 
 1651.00                                     NOT = ZEROS                                  151112 
 1652.00            AND WSAA-TOT-CLAWB-TOPUP                                              151113 
 1653.00                                     NOT = ZEROS                                  151113 
 1654.00                MOVE WSAA-TOT-CLAWB-NET                                           151112 
 1655.00                                        TO LIFA-ORIGAMT                           151112 
 1656.00                COMPUTE LIFA-ORIGAMT         = WSAA-TOT-CLAWB-NET                 151113 
 1657.00                                             * WSCC-NUM--1                        151113 
 1658.00                MOVE ZSCLABCK-CHDRNUM       TO WSAA-RLDG-CHDRNUM                  151112 
 1659.00       ***      MOVE '01'                   TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1660.00       ***      MOVE '02'                   TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1661.00       ***      MOVE '00'                   TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1662.00                MOVE WSAA-TU-LIFE           TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1663.00                MOVE WSAA-TU-COVERAGE       TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1664.00                MOVE WSAA-TU-RIDER          TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1665.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151112 
 1666.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151112 
 1667.00                MOVE WSAA-AGNTNUM           TO WSAA-TRANCHDR                      151113 
 1668.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151112 
 1669.00                MOVE 13                 TO IX-SA                                  151112 
 1670.00                PERFORM X1450-POST-COMM                                           151112 
 1671.00                MOVE 14                 TO IX-SA                                  151112 
 1672.00                PERFORM X1450-POST-COMM                                           151112 
 1673.00            END-IF                                                                151112 
 1674.00                                                                                  151117 
 1675.00            PERFORM X1900A-WRITE-ZCLB-TOPUP                                       151116 
 1676.00            .                                                                     151112 
 1677.00        2290-EXIT.                                                                151112 
 1678.00            EXIT.                                                                 151112 
 1679.00       /                                                                          151214 
 1680.00        2295-WRITE-LIFA-TOPUP SECTION.                                            151214 
 1681.00       ****************************                                               151214 
 1682.00        2295-START.                                                               151214 
 1683.00                                                                                  151214 
 1684.00             IF WSAA-CLAWBACK-TOPUP     = ZEROS                                   151214 
 1685.00                GO TO 2295-EXIT                                                   151214 
 1686.00             END-IF                                                               151214 
 1687.00            MOVE WSAA-ZTUD-JCOVCODE(WSAA-IND1)                                    151214 
 1688.00                                         TO WSAA-CRTABLE                          151214 
 1689.00            MOVE WSAA-ZTUD-RECODE(WSAA-IND1)                                      151214 
 1690.00                                         TO WSAA-EXT-RECODE                       151214 
 1691.00                                                                                  151214 
 1692.00            PERFORM X2050-READ-AGLF                                               151214 
 1693.00            PERFORM X1400-WRITE-LIFA-REGP                                         151214 
 1694.00                                                                                  151214 
 1695.00            IF  WSAA-CLAWBACK-OVRAMT                                              151214 
 1696.00                                     NOT  = ZEROS                                 151214 
 1697.00                MOVE ZSCLABCK-CHDRNUM       TO WSAA-RLDG-CHDRNUM                  151214 
 1698.00       ***      MOVE '01'                   TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1699.00       ***      MOVE '02'                   TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1700.00       ***      MOVE '00'                   TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1701.00                MOVE WSAA-TU-LIFE           TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1702.00                MOVE WSAA-TU-COVERAGE       TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1703.00                MOVE WSAA-TU-RIDER          TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1704.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151214 
 1705.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151214 
 1706.00                                                                                  151214 
 1707.00                COMPUTE LIFA-ORIGAMT ROUNDED = WSAA-CLAWBACK-OVRAMT               151214 
 1708.00                                             * WSCC-NUM--1                        151214 
 1709.00                                                                                  151214 
 1710.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR-TOP                      151214 
 1711.00                MOVE WSAA-TRANREF-TOP       TO LIFA-TRANREF                       151214 
 1712.00                MOVE 1                  TO IX-SA                                  151214 
 1713.00                PERFORM X1450-POST-COMM                                           151214 
 1714.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR-TOP                      151214 
 1715.00                MOVE WSAA-TRANREF-TOP       TO LIFA-TRANREF                       151214 
 1716.00                MOVE 11                 TO IX-SA                                  151214 
 1717.00                PERFORM X1450-POST-COMM                                           151214 
 1718.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR-TOP                      151214 
 1719.00                MOVE WSAA-TRANREF-TOP       TO LIFA-TRANREF                       151214 
 1720.00                MOVE 2                  TO IX-SA                                  151214 
 1721.00                PERFORM X1450-POST-COMM                                           151214 
 1722.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR-TOP                      151214 
 1723.00                MOVE WSAA-TRANREF-TOP       TO LIFA-TRANREF                       151214 
 1724.00                MOVE 12                 TO IX-SA                                  151214 
 1725.00                PERFORM X1450-POST-COMM                                           151214 
 1726.00            END-IF                                                                151214 
 1727.00            IF  WSAA-CLAWBACK-TOPUP                                               151214 
 1728.00                                     NOT = ZEROS                                  151214 
 1729.00                COMPUTE LIFA-ORIGAMT         = WSAA-CLAWBACK-TOPUP                151214 
 1730.00                                             * WSCC-NUM--1                        151214 
 1731.00       ***      MOVE '01'                   TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1732.00       ***      MOVE '02'                   TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1733.00       ***      MOVE '00'                   TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1734.00                MOVE WSAA-TU-LIFE           TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1735.00                MOVE WSAA-TU-COVERAGE       TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1736.00                MOVE WSAA-TU-RIDER          TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1737.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151214 
 1738.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151214 
 1739.00       *                                                                 <ATHB87> 170824 
 1740.00       * FOR TU05/TU06 WE DO NOT NEED TO WRITE ACCOUNT  52/0/@@@         <ATHB87> 170824 
 1741.00                IF  WSAA-CRTABLE         NOT = 'TU05'                    <ATHB87> 170824 
 1742.00                AND WSAA-CRTABLE         NOT = 'TU06'                    <ATHB87> 170824 
 1743.00                MOVE 4                  TO IX-SA                                  151214 
 1744.00                PERFORM X1450-POST-COMM                                           151214 
 1745.00                MOVE 8                  TO IX-SA                                  151214 
 1746.00                PERFORM X1450-POST-COMM                                           151214 
 1747.00                END-IF                                                   <ATHB87> 170824 
 1748.00                                                                                  151214 
 1749.00                MOVE SPACES             TO LIFA-RLDGACCT                          151214 
 1750.00                MOVE WSAA-AGNTNUM       TO LIFA-RLDGACCT                          151214 
 1751.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR-TOP                      151214 
 1752.00                MOVE WSAA-TRANREF-TOP       TO LIFA-TRANREF                       151214 
 1753.00                MOVE 9                  TO IX-SA                                  151214 
 1754.00                PERFORM X1450-POST-COMM                                           151214 
 1755.00                                                                                  151214 
 1756.00       ***      MOVE '01'                   TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1757.00       ***      MOVE '02'                   TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1758.00       ***      MOVE '00'                   TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1759.00                MOVE WSAA-TU-LIFE           TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1760.00                MOVE WSAA-TU-COVERAGE       TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1761.00                MOVE WSAA-TU-RIDER          TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1762.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151214 
 1763.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151214 
 1764.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR-TOP                      151214 
 1765.00                MOVE WSAA-TRANREF-TOP       TO LIFA-TRANREF                       151214 
 1766.00                MOVE 10                 TO IX-SA                                  151214 
 1767.00                PERFORM X1450-POST-COMM                                           151214 
 1768.00            END-IF                                                                151214 
 1769.00                                                                                  151214 
 1770.00            IF  WSAA-CLAWBACK-NET                                                 151214 
 1771.00                                     NOT = ZEROS                                  151214 
 1772.00            AND WSAA-CLAWBACK-TOPUP                                               151214 
 1773.00                                     NOT = ZEROS                                  151214 
 1774.00                COMPUTE LIFA-ORIGAMT         = WSAA-CLAWBACK-NET                  151214 
 1775.00                                             * WSCC-NUM--1                        151214 
 1776.00                MOVE ZSCLABCK-CHDRNUM       TO WSAA-RLDG-CHDRNUM                  151214 
 1777.00       ***      MOVE '01'                   TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1778.00       ***      MOVE '02'                   TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1779.00       ***      MOVE '00'                   TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1780.00                MOVE WSAA-TU-LIFE           TO WSAA-RLDG-LIFE            <ATHB45> 170313 
 1781.00                MOVE WSAA-TU-COVERAGE       TO WSAA-RLDG-COVERAGE        <ATHB45> 170313 
 1782.00                MOVE WSAA-TU-RIDER          TO WSAA-RLDG-RIDER           <ATHB45> 170313 
 1783.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151214 
 1784.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151214 
 1785.00                MOVE WSAA-AGNTNUM           TO WSAA-TRANCHDR-TOP                  151214 
 1786.00                MOVE WSAA-TRANREF-TOP       TO LIFA-TRANREF                       151214 
 1787.00                MOVE 13                 TO IX-SA                                  151214 
 1788.00                PERFORM X1450-POST-COMM                                           151214 
 1789.00                MOVE 14                 TO IX-SA                                  151214 
 1790.00                PERFORM X1450-POST-COMM                                           151214 
 1791.00            END-IF                                                                151214 
 1792.00                                                                                  151214 
 1793.00            PERFORM X1900B-WRITE-ZCLB-TOPUP                                       151214 
 1794.00            .                                                                     151214 
 1795.00        2295-EXIT.                                                                151214 
 1796.00            EXIT.                                                                 151214 
 1797.00       /                                                                 <ATHD11> 181012 
 1798.00        2900-SURRF-CLAWBACK SECTION.                                     <ATHD11> 181012 
 1799.00       ****************************                                      <ATHD11> 181012 
 1800.00        2900-START.                                                      <ATHD11> 181012 
 1801.00            IF  CLAWBACK-REGP                                            <ATHD11> 181012 
 1802.00                IF WSAA-ZCHD-CLNTNUM NOT = WSAA-ZCHA-CLNTNUM             <ATHD11> 181012 
 1803.00                   SET NOT-CLAWBACK-REGP TO TRUE                         <ATHD11> 181012 
 1804.00                END-IF                                                   <ATHD11> 181012 
 1805.00            END-IF                                                       <ATHD11> 181012 
 1806.00                                                                         <ATHD11> 181012 
 1807.00       * FOR REGULAR PREMIUM                                             <ATHD11> 181012 
 1808.00            IF  CLAWBACK-REGP                                            <ATHD11> 181012 
 1809.00                PERFORM 2250-READ-ACMV                                   <ATHD11> 181012 
 1810.00            END-IF                                                       <ATHD11> 181012 
 1811.00            PERFORM 2257-READ-ZTUD-REGP                                  <ATHD11> 181012 
 1812.00            .                                                            <ATHD11> 181012 
 1813.00        2900-EXIT.                                                       <ATHD11> 181012 
 1814.00            EXIT.                                                        <ATHD11> 181012 
 1815.00       /                                                                          151116 
 1816.00        2400-SURCF-CLAWBACK SECTION.                                              151116 
 1817.00       ****************************                                               151116 
 1818.00        2400-START.                                                               151116 
 1819.00            IF  CLAWBACK-REGP                                            <ATHA67> 160408 
 1820.00                IF WSAA-ZCHD-CLNTNUM NOT = WSAA-ZCHA-CLNTNUM             <ATHA67> 160408 
 1821.00                   SET NOT-CLAWBACK-REGP TO TRUE                         <ATHA67> 160408 
 1822.00                END-IF                                                   <ATHA67> 160408 
 1823.00            END-IF                                                       <ATHA67> 160408 
 1824.00                                                                                  151116 
 1825.00       * FOR REGULAR PREMIUM                                                      151116 
 1826.00       ***  IF  CLAWBACK-REGP                                            <ATHA67> 160512 
 1827.00                PERFORM 2250-READ-ACMV                                            151116 
 1828.00       ***  END-IF                                                       <ATHA67> 160512 
 1829.00            PERFORM 2257-READ-ZTUD-REGP                                  <ATHA43> 160323 
 1830.00            SET NOT-CHECK-AGENT         TO TRUE                          <ATHA67> 160512 
 1831.00       * FOR TOP UP                                                               151116 
 1832.00            PERFORM X4400-GET-TU-COVR                                    <ATHB45> 170313 
 1833.00            IF  WSAA-TU-CRTABLE NOT = SPACES                             <ATHB45> 170313 
 1834.00                PERFORM X4800-READ-ZCOVCRT                               <ATHB45> 170313 
 1835.00            END-IF                                                       <ATHB45> 170313 
 1836.00            PERFORM 2270-READ-ZTUD-TOPUP                                          151116 
 1837.00            PERFORM 2280-READ-ZTUD-ARRAY                                          151116 
 1838.00       **   PERFORM 2290-WRITE-LIFA-TOPUP                                <ATHA67> 160407 
 1839.00            .                                                                     151116 
 1840.00        2400-EXIT.                                                                151116 
 1841.00            EXIT.                                                                 151116 
 1842.00       /                                                                          151103 
 1843.00        2300-SURP-CLAWBACK SECTION.                                               151103 
 1844.00       ****************************                                               151103 
 1845.00        2300-START.                                                               151103 
 1846.00            IF  CLAWBACK-REGP                                            <ATHA67> 160408 
 1847.00                IF WSAA-ZCHD-CLNTNUM NOT = WSAA-ZCHA-CLNTNUM             <ATHA67> 160408 
 1848.00                   SET NOT-CLAWBACK-REGP TO TRUE                         <ATHA67> 160408 
 1849.00                END-IF                                                   <ATHA67> 160408 
 1850.00            END-IF                                                       <ATHA67> 160408 
 1851.00            IF  CLAWBACK-REGP                                            <ATHA43> 160324 
 1852.00                PERFORM 2250-READ-ACMV                                   <ATHA43> 160324 
 1853.00            END-IF                                                       <ATHA43> 160324 
 1854.00                                                                         <ATHA43> 160323 
 1855.00            PERFORM 2257-READ-ZTUD-REGP                                  <ATHA43> 160323 
 1856.00       * FOR TOP UP                                                      <ATHA43> 160205 
 1857.00            PERFORM X4400-GET-TU-COVR                                    <ATHB45> 170313 
 1858.00            IF  WSAA-TU-CRTABLE NOT = SPACES                             <ATHB45> 170313 
 1859.00                PERFORM X4800-READ-ZCOVCRT                               <ATHB45> 170313 
 1860.00            END-IF                                                       <ATHB45> 170313 
 1861.00            PERFORM 2270-READ-ZTUD-TOPUP                                 <ATHA43> 160205 
 1862.00            PERFORM 2280-READ-ZTUD-ARRAY                                 <ATHA43> 160205 
 1863.00       ***  PERFORM 2290-WRITE-LIFA-TOPUP                        <ATHA67><ATHA43> 160407 
 1864.00            .                                                            <ATHA43> 160205 
 1865.00        2300-EXIT.                                                                151103 
 1866.00            EXIT.                                                                 151103 
 1867.00       /                                                                          151122 
 1868.00        2950-SURPC-CLAWBACK SECTION.                                     <ATHD11> 181016 
 1869.00       ****************************                                      <ATHD11> 181016 
 1870.00        2950-START.                                                      <ATHD11> 181016 
 1871.00                                                                         <ATHD11> 181016 
 1872.00            MOVE ZSCLABCK-CRTABLE       TO T5673-CTABLE                  <ATHD11> 181016 
 1873.00            MOVE WSCC-NUM-1             TO WSAA-IND1                     <ATHD11> 181016 
 1874.00            PERFORM X4450-GET-CRTABLE-TYPE                               <ATHD11> 181016 
 1875.00                                                                         <ATHD11> 181018 
 1876.00            IF CRTABLE-TYPE-UL                                           <ATHD11> 181016 
 1877.00               PERFORM 2900-SURRF-CLAWBACK                               <ATHD11> 181016 
 1878.00            END-IF                                                       <ATHD11> 181016 
 1879.00                                                                         <ATHD11> 181016 
 1880.00            IF CRTABLE-TYPE-TOP-UP                                       <ATHD11> 181016 
 1881.00               SET CLAWBACK-COVER       TO TRUE                          <ATHD11> 181018 
 1882.00               PERFORM 2270-READ-ZTUD-TOPUP                              <ATHD11> 181016 
 1883.00               PERFORM 2280-READ-ZTUD-ARRAY                              <ATHD11> 181016 
 1884.00       ****    PERFORM 2290-WRITE-LIFA-TOPUP                             <ATHD11> 181022 
 1885.00            END-IF                                                       <ATHD11> 181016 
 1886.00            .                                                            <ATHD11> 181016 
 1887.00        2950-EXIT.                                                       <ATHD11> 181016 
 1888.00            EXIT.                                                        <ATHD11> 181016 
 1889.00                                                                         <ATHD11> 181016 
 1890.00        2500-SURSP-CLAWBACK SECTION.                                              151122 
 1891.00       ****************************                                               151122 
 1892.00        2500-START.                                                               151122 
 1893.00                                                                                  151122 
 1894.00       * FOR SINGLE PREMIUM                                                       151122 
 1895.00            IF  CLAWBACK-REGP                                                     151122 
 1896.00                PERFORM 2550-READ-ACMV-SINGLE-PREM                                151122 
 1897.00            END-IF                                                                151122 
 1898.00            .                                                                     151122 
 1899.00        2500-EXIT.                                                                151122 
 1900.00            EXIT.                                                                 151122 
 1901.00       /                                                                 <ATHA67> 160407 
 1902.00        2600-SURGG-CLAWBACK SECTION.                                     <ATHA67> 160407 
 1903.00       ****************************                                      <ATHA67> 160407 
 1904.00        2600-START.                                                      <ATHA67> 160407 
 1905.00            IF  CLAWBACK-REGP                                            <ATHA67> 160408 
 1906.00                IF WSAA-ZCHD-CLNTNUM NOT = WSAA-ZCHA-CLNTNUM             <ATHA67> 160408 
 1907.00                   SET NOT-CLAWBACK-REGP TO TRUE                         <ATHA67> 160408 
 1908.00                END-IF                                                   <ATHA67> 160408 
 1909.00            END-IF                                                       <ATHA67> 160408 
 1910.00                                                                         <ATHA67> 160407 
 1911.00       * FOR SINGLE PREMIUM                                              <ATHA67> 160407 
 1912.00            IF  CLAWBACK-REGP                                            <ATHA67> 160407 
 1913.00                PERFORM 2550-READ-ACMV-SINGLE-PREM                       <ATHA67> 160407 
 1914.00            END-IF                                                       <ATHA67> 160407 
 1915.00            PERFORM 2257-READ-ZTUD-REGP                                  <ATHA67> 160407 
 1916.00                                                                         <ATHA67> 160407 
 1917.00            MOVE ZEROS                  TO WSAA-T8Z82                    <ATHA67> 160407 
 1918.00       * FOR TOP UP                                                      <ATHA67> 160407 
 1919.00            PERFORM X4400-GET-TU-COVR                                    <ATHB45> 170313 
 1920.00            IF  WSAA-TU-CRTABLE NOT = SPACES                             <ATHB45> 170313 
 1921.00                PERFORM X4800-READ-ZCOVCRT                               <ATHB45> 170313 
 1922.00            END-IF                                                       <ATHB45> 170313 
 1923.00            PERFORM 2270-READ-ZTUD-TOPUP                                 <ATHA67> 160407 
 1924.00            PERFORM 2280-READ-ZTUD-ARRAY                                 <ATHA67> 160407 
 1925.00       **** PERFORM 2290-WRITE-LIFA-TOPUP                                <ATHA67> 160407 
 1926.00            .                                                            <ATHA67> 160407 
 1927.00        2600-EXIT.                                                       <ATHA67> 160413 
 1928.00            EXIT.                                                        <ATHA67> 160407 
 1929.00       /                                                                          151122 
 1930.00        2550-READ-ACMV-SINGLE-PREM SECTION.                                       151122 
 1931.00       ************************************                                       151122 
 1932.00        2550-START.                                                               151122 
 1933.00                                                                                  151122 
 1934.00            MOVE ZSCLABCK-CHDRNUM        TO WSAA-ACMV-CHDRNUM                     151122 
 1935.00            MOVE '01'                   TO WSAA-ACMV-LIFE                         151122 
 1936.00            MOVE '01'                   TO WSAA-ACMV-COVERAGE                     151122 
 1937.00            MOVE '00'                   TO WSAA-ACMV-RIDER                        151122 
 1938.00            MOVE '00'                   TO WSAA-ACMV-PLAN-SUFF                    151122 
 1939.00            INITIALIZE ACMVBK3-PARAMS                                             151122 
 1940.00            INITIALIZE ACMVBK3REC-KEY-DATA     OF ACMVBK3-PARAMS                  151122 
 1941.00            INITIALIZE ACMVBK3REC-NON-KEY-DATA OF ACMVBK3-PARAMS                  151122 
 1942.00            MOVE ZSCLABCK-CHDRCOY       TO ACMVBK3-RLDGCOY                        151122 
 1943.00            MOVE WSAA-ACMV-RLDGACCT     TO ACMVBK3-RLDGACCT                       151122 
 1944.00       *    MOVE WSCC-LE                TO ACMVBK3-SACSCODE                       151122 
 1945.00       *    MOVE WSCC-PS                TO ACMVBK3-SACSTYP                        151122 
 1946.00            MOVE BEGN                   TO ACMVBK3-FUNCTION                       151122 
 1947.00            PERFORM X1150-ACMVBK3-IO                                              151122 
 1948.00            PERFORM                                                               151122 
 1949.00              UNTIL ACMVBK3-STATUZ       = ENDP                                   151122 
 1950.00                                                                                  151122 
 1951.00                 MOVE 'T642'            TO WSAA-BATCTRCDE                <ATHA67> 160413 
 1952.00                 PERFORM X2200-READ-PTRNREV                              <ATHA67> 160413 
 1953.00                                                                                  151122 
 1954.00                 IF  VALID-RECORD                                        <ATHA67> 160413 
 1955.00                 IF  ACMVBK3-EFFDATE     = WSAA-OCCDATE                           151122 
 1956.00                 AND ACMVBK3-RLDGACCT    = WSAA-ACMV-RLDGACCT                     151123 
 1957.00                     IF  ACMVBK3-SACSCODE = WSCC-LE                               151122 
 1958.00                     AND ACMVBK3-SACSTYP  = WSCC-PS                               151122 
 1959.00                         COMPUTE WSAA-PAID-PREM                                   151122 
 1960.00                                         = WSAA-PAID-PREM                         151122 
 1961.00                                         + ACMVBK3-ORIGAMT                        151122 
 1962.00                     END-IF                                                       151122 
 1963.00                     IF  ACMVBK3-SACSCODE = WSAA-T5645-SACSCODE(1)                151122 
 1964.00                     AND ACMVBK3-SACSTYP  = WSAA-T5645-SACSTYPE(1)                151122 
 1965.00                         COMPUTE WSAA-PAID-OVRCOM                                 151122 
 1966.00                                         = WSAA-PAID-OVRCOM                       151122 
 1967.00                                         + ACMVBK3-ORIGAMT                        151122 
 1968.00                     END-IF                                                       151122 
 1969.00                     IF  ACMVBK3-SACSCODE = WSAA-T5645-SACSCODE(17)               151122 
 1970.00                     AND ACMVBK3-SACSTYP  = WSAA-T5645-SACSTYPE(17)               151122 
 1971.00                         COMPUTE WSAA-PAID-COMM                                   151122 
 1972.00                                         = WSAA-PAID-COMM                         151122 
 1973.00                                         + ACMVBK3-ORIGAMT                        151122 
 1974.00                         MOVE ACMVBK3-GLCODE(11: 4)                               151122 
 1975.00                                        TO WSAA-CRTABLE                           151122 
 1976.00                     END-IF                                                       151122 
 1977.00                 END-IF                                                           151122 
 1978.00                 IF  ACMVBK3-EFFDATE  = WSAA-OCCDATE                     <ATHA67> 160414 
 1979.00                 AND ACMVBK3-SACSCODE = 'LA'                             <ATHA67> 160414 
 1980.00                 AND ACMVBK3-SACSTYP  = 'IP'                             <ATHA67> 160414 
 1981.00                     MOVE ACMVBK3-RLDGACCT(1:8)                          <ATHA67> 160414 
 1982.00                                        TO WSAA-AGNTNUM                  <ATHA67> 160413 
 1983.00                 END-IF                                                  <ATHA67> 160414 
 1984.00                 END-IF                                                  <ATHA67> 160413 
 1985.00                                                                                  151122 
 1986.00                 MOVE NEXTR             TO ACMVBK3-FUNCTION                       151122 
 1987.00                 PERFORM X1150-ACMVBK3-IO                                         151122 
 1988.00            END-PERFORM                                                           151122 
 1989.00                                                                                  151122 
 1990.00                                                                                  151122 
 1991.00            COMPUTE WSAA-PAID-PREM-CLAWB ROUNDED                                  151122 
 1992.00                                         = WSAA-PAID-PREM                         151122 
 1993.00                                         * WSAA-T8Z82                             151122 
 1994.00                                         * (WSAA-PARTS-PERC              <ATHA43> 160225 
 1995.00                                         / 100)                          <ATHA43> 160225 
 1996.00            COMPUTE WSAA-PAID-COMM-CLAWB ROUNDED                                  151122 
 1997.00                                         = WSAA-PAID-COMM                         151122 
 1998.00                                         * WSAA-T8Z82                             151122 
 1999.00                                         * (WSAA-PARTS-PERC              <ATHA43> 160225 
 2000.00                                         / 100)                          <ATHA43> 160225 
 2001.00            COMPUTE WSAA-PAID-OVRCOM-CLAWB ROUNDED                                151122 
 2002.00                                         = WSAA-PAID-OVRCOM                       151122 
 2003.00                                         * WSAA-T8Z82                             151122 
 2004.00                                         * (WSAA-PARTS-PERC              <ATHA43> 160225 
 2005.00                                         / 100)                          <ATHA43> 160225 
 2006.00       *******                                                           <ATHA67> 160404 
 2007.00            MOVE '01'                   TO WSAA-ZCLB-LIFE                <ATHA67> 160404 
 2008.00            MOVE '01'                   TO WSAA-ZCLB-COVERAGE            <ATHA67> 160404 
 2009.00            MOVE '00'                   TO WSAA-ZCLB-RIDER               <ATHA67> 160404 
 2010.00            MOVE '00'                   TO WSAA-ZCLB-RECODE              <ATHA67> 160408 
 2011.00            MOVE COVRAFI-CRTABLE        TO WSAA-CRTABLE                  <ATHB37> 170215 
 2012.00            PERFORM X3000-READ-ZCLBCOV                                   <ATHA67> 160404 
 2013.00            PERFORM X3100-FIND-CLAWB-REMN-REGP                           <ATHA67> 160404 
 2014.00                                                                         <ATHA67> 160404 
 2015.00            PERFORM X1900-WRITE-ZCLB                                              151122 
 2016.00                                                                                  151122 
 2017.00            PERFORM X1400-WRITE-LIFA-REGP                                         151122 
 2018.00            PERFORM X2110-SP-ACCOUNTINGS                                          151122 
 2019.00            .                                                                     151122 
 2020.00        2550-EXIT.                                                                151122 
 2021.00            EXIT.                                                                 151122 
 2022.00       /                                                                 <ATHA67> 160413 
 2023.00        2700-CFIGG-CLAWBACK SECTION.                                     <ATHA67> 160413 
 2024.00       ****************************                                      <ATHA67> 160413 
 2025.00        2700-START.                                                      <ATHA67> 160413 
 2026.00                                                                         <ATHA67> 160413 
 2027.00            SET NOT-CHECK-AGENT         TO TRUE                          <ATHA67> 160414 
 2028.00       * FOR SINGLE PREMIUM                                              <ATHA67> 160413 
 2029.00            PERFORM 2550-READ-ACMV-SINGLE-PREM                           <ATHA67> 160413 
 2030.00            PERFORM 2257-READ-ZTUD-REGP                                  <ATHA67> 160413 
 2031.00                                                                         <ATHA67> 160413 
 2032.00            MOVE ZEROS                  TO WSAA-T8Z82                    <ATHA67> 160413 
 2033.00       * FOR TOP UP                                                      <ATHA67> 160413 
 2034.00            PERFORM X4400-GET-TU-COVR                                    <ATHB45> 170313 
 2035.00            IF  WSAA-TU-CRTABLE NOT = SPACES                             <ATHB45> 170313 
 2036.00                PERFORM X4800-READ-ZCOVCRT                               <ATHB45> 170313 
 2037.00            END-IF                                                       <ATHB45> 170313 
 2038.00            PERFORM 2270-READ-ZTUD-TOPUP                                 <ATHA67> 160413 
 2039.00            PERFORM 2280-READ-ZTUD-ARRAY                                 <ATHA67> 160413 
 2040.00       **** PERFORM 2290-WRITE-LIFA-TOPUP                                <ATHA67> 160413 
 2041.00            .                                                            <ATHA67> 160413 
 2042.00        2700-EXIT.                                                       <ATHA67> 160413 
 2043.00            EXIT.                                                        <ATHA67> 160413 
 2044.00       /                                                                 <ATHB37> 170208 
 2045.00        2800-DECRESE-PREM-CLAWBACK SECTION.                              <ATHB37> 170208 
 2046.00       ************************************                              <ATHB37> 170208 
 2047.00        2800-START.                                                      <ATHB37> 170208 
 2048.00            IF  CLAWBACK-REGP                                            <ATHB37> 170208 
 2049.00                IF WSAA-ZCHD-CLNTNUM NOT = WSAA-ZCHA-CLNTNUM             <ATHB37> 170208 
 2050.00                   SET NOT-CLAWBACK-REGP TO TRUE                         <ATHB37> 170208 
 2051.00                END-IF                                                   <ATHB37> 170208 
 2052.00            END-IF                                                       <ATHB37> 170208 
 2053.00                                                                         <ATHB37> 170208 
 2054.00       * FOR REGULAR PREMIUM                                             <ATHB37> 170208 
 2055.00            IF  CLAWBACK-REGP                                            <ATHB37> 170208 
 2056.00                PERFORM 2850-FIND-INITIAL                                <ATHB37> 170210 
 2057.00                PERFORM 2860-FIND-PAID-PREM                              <ATHB37> 170213 
 2058.00            END-IF                                                       <ATHB37> 170208 
 2059.00            .                                                            <ATHB37> 170208 
 2060.00        2800-EXIT.                                                       <ATHB37> 170210 
 2061.00            EXIT.                                                        <ATHB37> 170208 
 2062.00       /                                                                 <ATHB37> 170210 
 2063.00        2850-FIND-INITIAL SECTION.                                       <ATHB37> 170210 
 2064.00       ***************************                                       <ATHB37> 170210 
 2065.00        2850-START.                                                      <ATHB37> 170210 
 2066.00                                                                         <ATHB37> 170210 
 2067.00            INITIALIZE COVRAFI-PARAMS                                    <ATHB37> 170210 
 2068.00            INITIALIZE COVRAFIREC-KEY-DATA OF COVRAFI-PARAMS             <ATHB37> 170210 
 2069.00            INITIALIZE COVRAFIREC-NON-KEY-DATA                           <ATHB37> 170210 
 2070.00                                        OF COVRAFI-PARAMS                <ATHB37> 170210 
 2071.00                                                                         <ATHB37> 170210 
 2072.00            MOVE ZSCLABCK-CHDRCOY       TO COVRAFI-CHDRCOY               <ATHB37> 170210 
 2073.00            MOVE ZSCLABCK-CHDRNUM       TO COVRAFI-CHDRNUM               <ATHB37> 170210 
 2074.00            MOVE ZSCLABCK-COVERAGE      TO COVRAFI-COVERAGE              <ATHB37> 170210 
 2075.00            MOVE ZSCLABCK-RIDER         TO COVRAFI-RIDER                 <ATHB37> 170210 
 2076.00            MOVE ZSCLABCK-LIFE          TO COVRAFI-LIFE                  <ATHB37> 170210 
 2077.00            MOVE ZSCLABCK-PLAN-SUFFIX   TO COVRAFI-PLAN-SUFFIX           <ATHB37> 170210 
 2078.00                                                                         <ATHB37> 170210 
 2079.00            MOVE BEGN                   TO COVRAFI-FUNCTION              <ATHB37> 170210 
 2080.00            PERFORM X3600-COVRAFI-IO                                     <ATHB37> 170210 
 2081.00            IF  COVRAFI-STATUZ           = ENDP                          <ATHB37> 170210 
 2082.00                GO TO 2850-EXIT                                          <ATHB37> 170210 
 2083.00            END-IF                                                       <ATHB37> 170210 
 2084.00                                                                         <ATHB37> 170210 
 2085.00            INITIALIZE CHDRAFI-PARAMS                                    <ATHB37> 170210 
 2086.00            INITIALIZE CHDRAFIREC-KEY-DATA OF CHDRAFI-PARAMS             <ATHB37> 170210 
 2087.00            INITIALIZE CHDRAFIREC-NON-KEY-DATA                           <ATHB37> 170210 
 2088.00                                        OF CHDRAFI-PARAMS                <ATHB37> 170210 
 2089.00                                                                         <ATHB37> 170210 
 2090.00            MOVE COVRAFI-CHDRCOY        TO CHDRAFI-CHDRCOY               <ATHB37> 170210 
 2091.00            MOVE COVRAFI-CHDRNUM        TO CHDRAFI-CHDRNUM               <ATHB37> 170210 
 2092.00            MOVE COVRAFI-TRANNO         TO CHDRAFI-TRANNO                <ATHB37> 170210 
 2093.00                                                                         <ATHB37> 170210 
 2094.00            MOVE BEGN                   TO CHDRAFI-FUNCTION              <ATHB37> 170210 
 2095.00            PERFORM X3700-CHDRAFI-IO                                     <ATHB37> 170210 
 2096.00                                                                         <ATHB37> 170210 
 2097.00            MOVE CHDRAFI-BILLFREQ       TO WSAA-BILLFREQ                 <ATHB37> 170210 
 2098.00                                                                         <ATHB37> 170210 
 2099.00            COMPUTE WSAA-INIT-ANNPREM ROUNDED                            <ATHB37> 170210 
 2100.00                                         = COVRAFI-INSTPREM              <ATHB37> 170210 
 2101.00                                         * WSAA-BILLFREQ-NUM             <ATHB37> 170210 
 2102.00            .                                                            <ATHB37> 170210 
 2103.00        2850-EXIT.                                                       <ATHB37> 170210 
 2104.00            EXIT.                                                        <ATHB37> 170210 
 2105.00       /                                                                 <ATHB37> 170210 
 2106.00        2860-FIND-PAID-PREM SECTION.                                     <ATHB37> 170210 
 2107.00       ***************************                                       <ATHB37> 170210 
 2108.00        2860-START.                                                      <ATHB37> 170210 
 2109.00                                                                         <ATHB37> 170210 
 2110.00            PERFORM VARYING WSAA-IND2 FROM 1 BY 1                        <ATHB37> 170214 
 2111.00               UNTIL WSAA-IND2           > WSAA-COUNT-YEAR               <ATHB37> 170213 
 2112.00                     MOVE WSAA-FROM-DATE-W(WSAA-IND2)                    <ATHB37> 170210 
 2113.00                                        TO WSAA-OCCDATE                  <ATHB37> 170210 
 2114.00                     MOVE WSAA-TO-DATE-W(WSAA-IND2)                      <ATHB37> 170210 
 2115.00                                        TO WSAA-NEXT-ANNI-DATE           <ATHB37> 170210 
 2116.00                                                                         <ATHB37> 170210 
 2117.00                     PERFORM 2865-READ-ACMV-DECREASE                     <ATHB37> 170213 
 2118.00                                                                         <ATHB37> 170210 
 2119.00                     MOVE WSAA-PAID-PREM                                 <ATHB37> 170210 
 2120.00                                        TO WSAA-PAID-PREM-RP(WSAA-IND2)  <ATHB37> 170210 
 2121.00                     MOVE WSAA-PAID-OVRCOM                               <ATHB37> 170210 
 2122.00                                        TO WSAA-PAID-OVRC-RP(WSAA-IND2)  <ATHB37> 170210 
 2123.00                     MOVE WSAA-PAID-COMM                                 <ATHB37> 170210 
 2124.00                                        TO WSAA-PAID-COMM-RP(WSAA-IND2)  <ATHB37> 170210 
 2125.00            END-PERFORM                                                  <ATHB37> 170214 
 2126.00                                                                         <ATHB37> 170210 
 2127.00            EVALUATE WSAA-COUNT-YEAR                                     <ATHB37> 170214 
 2128.00            WHEN 1                                                       <ATHB37> 170214 
 2129.00                 PERFORM 2861-FIRST-YEAR-CLAWB                           <ATHB37> 170214 
 2130.00            WHEN OTHER                                                   <ATHB37> 170214 
 2131.00                 PERFORM 2862-NEXT-YEAR-CLAWB                            <ATHB37> 170214 
 2132.00            END-EVALUATE                                                 <ATHB37> 170214 
 2133.00                                                                         <ATHB37> 170215 
 2134.00            IF  WSAA-DIFF-PREM         <= 0                              <ATHB37> 170215 
 2135.00                GO TO 2860-EXIT                                          <ATHB37> 170215 
 2136.00            END-IF                                                       <ATHB37> 170215 
 2137.00                                                                         <ATHB37> 170214 
 2138.00       * COMMISSIONABLE PREMIUM                                          <ATHB37> 170214 
 2139.00            COMPUTE WSAA-PAID-PREM-CLAWB ROUNDED                         <ATHB37> 170214 
 2140.00                                        = (WSAA-DIFF-PREM                <ATHB37> 170214 
 2141.00                                        * WSAA-T8Z82)                    <ATHB37> 170214 
 2142.00            MOVE WSAA-PAID-PREM-CLAWB   TO WSAA-PREM-CLAWB               <ATHB37> 170215 
 2143.00                                                                         <ATHB37> 170215 
 2144.00            MOVE WSAA-PAID-PREM-RP(1)   TO WSAA-PAID-PREM                <ATHB37> 170215 
 2145.00            MOVE WSAA-PAID-OVRC-RP(1)   TO WSAA-PAID-OVRCOM              <ATHB37> 170215 
 2146.00            MOVE WSAA-PAID-COMM-RP(1)   TO WSAA-PAID-COMM                <ATHB37> 170215 
 2147.00       * CALCULATE COMMISSIONS                                           <ATHB37> 170214 
 2148.00            PERFORM 2868-CALC-COMM                                       <ATHB37> 170214 
 2149.00       * CALCULATE OVERCOMMISSIONS                                       <ATHB37> 170214 
 2150.00            PERFORM 2869-CALC-OVRCOM                                     <ATHB37> 170214 
 2151.00       * REGISTER CLAWBACK/ CHECK REMAINING AMOUNT                       <ATHB37> 170215 
 2152.00            MOVE ZSCLABCK-LIFE          TO WSAA-ZCLB-LIFE                <ATHB37> 170215 
 2153.00            MOVE ZSCLABCK-COVERAGE      TO WSAA-ZCLB-COVERAGE            <ATHB37> 170215 
 2154.00            MOVE ZSCLABCK-RIDER         TO WSAA-ZCLB-RIDER               <ATHB37> 170215 
 2155.00            MOVE '00'                   TO WSAA-ZCLB-RECODE              <ATHB37> 170215 
 2156.00            MOVE ZSCLABCK-CRTABLE       TO WSAA-CRTABLE                  <ATHB37> 170215 
 2157.00            PERFORM X3000-READ-ZCLBCOV                                   <ATHB37> 170215 
 2158.00            PERFORM X3100-FIND-CLAWB-REMN-REGP                           <ATHB37> 170215 
 2159.00            IF  WSAA-PAID-COMM-CLAWB     = ZEROS                         <ATHB37> 170215 
 2160.00                GO TO 2860-EXIT                                          <ATHB37> 170215 
 2161.00            END-IF                                                       <ATHB37> 170215 
 2162.00                                                                         <ATHB37> 170215 
 2163.00            PERFORM X1900-WRITE-ZCLB                                     <ATHB37> 170215 
 2164.00       * POST COMMISSIONABLE PREMIUM/ COMMISSIONS/OVERCOMMISSIONS        <ATHB37> 170215 
 2165.00            PERFORM X1400-WRITE-LIFA-REGP                                <ATHB37> 170214 
 2166.00            PERFORM X2000-DUE-ACCOUNTINGS                                <ATHB37> 170214 
 2167.00            PERFORM X2100-COLL-ACCOUNTINGS                               <ATHB37> 170214 
 2168.00            .                                                            <ATHB37> 170210 
 2169.00        2860-EXIT.                                                       <ATHB37> 170210 
 2170.00            EXIT.                                                        <ATHB37> 170210 
 2171.00       /                                                                 <ATHB37> 170210 
 2172.00        2861-FIRST-YEAR-CLAWB SECTION.                                   <ATHB37> 170210 
 2173.00       ***************************                                       <ATHB37> 170210 
 2174.00        2861-START.                                                      <ATHB37> 170210 
 2175.00             IF  WSAA-INIT-ANNPREM       > WSAA-PAID-PREM-RP             <ATHB37> 170210 
 2176.00                                          (WSAA-COUNT-YEAR)              <ATHB37> 170213 
 2177.00                 COMPUTE WSAA-DIFF-PREM  = WSAA-INIT-ANNPREM             <ATHB37> 170213 
 2178.00                                         - WSAA-PAID-PREM-RP             <ATHB37> 170210 
 2179.00                                          (WSAA-COUNT-YEAR)              <ATHB37> 170213 
 2180.00             END-IF                                                      <ATHB37> 170210 
 2181.00            .                                                            <ATHB37> 170210 
 2182.00        2861-EXIT.                                                       <ATHB37> 170210 
 2183.00            EXIT.                                                        <ATHB37> 170210 
 2184.00       /                                                                 <ATHB37> 170210 
 2185.00        2862-NEXT-YEAR-CLAWB SECTION.                                    <ATHB37> 170213 
 2186.00       ******************************                                    <ATHB37> 170213 
 2187.00        2862-START.                                                      <ATHB37> 170210 
 2188.00                                                                         <ATHB37> 170214 
 2189.00       * FIND THE MINIMUM BETWEEN THE INITIAL PREMIUM                    <ATHB37> 170214 
 2190.00       * AND PREVIEWS YEARS PREMIUM                                      <ATHB37> 170214 
 2191.00                                                                         <ATHB37> 170214 
 2192.00             MOVE WSAA-INIT-ANNPREM     TO WSAA-MIN-ANNPREM              <ATHB37> 170214 
 2193.00             PERFORM VARYING WSAA-IND2 FROM 1 BY 1                       <ATHB37> 170214 
 2194.00               UNTIL WSAA-IND2           > (WSAA-COUNT-YEAR - 1)         <ATHB37> 170214 
 2195.00                   IF  WSAA-PAID-PREM-RP(WSAA-IND2)                      <ATHB37> 170214 
 2196.00                                         < WSAA-MIN-ANNPREM              <ATHB37> 170214 
 2197.00                       MOVE WSAA-PAID-PREM-RP(WSAA-IND2)                 <ATHB37> 170214 
 2198.00                                        TO WSAA-MIN-ANNPREM              <ATHB37> 170214 
 2199.00                   END-IF                                                <ATHB37> 170214 
 2200.00             END-PERFORM                                                 <ATHB37> 170214 
 2201.00                                                                         <ATHB37> 170213 
 2202.00             IF  WSAA-MIN-ANNPREM        > WSAA-PAID-PREM-RP             <ATHB37> 170214 
 2203.00                                          (WSAA-COUNT-YEAR)              <ATHB37> 170213 
 2204.00                 COMPUTE WSAA-DIFF-PREM  = WSAA-MIN-ANNPREM              <ATHB37> 170214 
 2205.00                                         - WSAA-PAID-PREM-RP             <ATHB37> 170210 
 2206.00                                          (WSAA-COUNT-YEAR)              <ATHB37> 170213 
 2207.00             END-IF                                                      <ATHB37> 170214 
 2208.00            .                                                            <ATHB37> 170210 
 2209.00        2862-EXIT.                                                       <ATHB37> 170210 
 2210.00            EXIT.                                                        <ATHB37> 170210 
 2211.00       /                                                                 <ATHB37> 170213 
 2212.00        2865-READ-ACMV-DECREASE SECTION.                                 <ATHB37> 170213 
 2213.00       *********************************                                 <ATHB37> 170213 
 2214.00        2865-START.                                                      <ATHB37> 170213 
 2215.00                                                                         <ATHB37> 170213 
 2216.00            INITIALIZE WSAA-ACMV-ARRAY                                   <ATHB37> 170213 
 2217.00            MOVE ZEROS                  TO WSAA-PAID-PREM                <ATHB37> 170215 
 2218.00            MOVE ZEROS                  TO WSAA-PAID-COMM                <ATHB37> 170215 
 2219.00            MOVE ZEROS                  TO WSAA-PAID-OVRCOM              <ATHB37> 170215 
 2220.00            MOVE ZEROS                  TO WSAA-LAST-TRANNO              <ATHB37> 170215 
 2221.00            MOVE ZEROS                  TO WSAA-ACMV-ARRAY-CNT           <ATHB37> 170213 
 2222.00            MOVE ZEROS                  TO WSAA-LAST-TRANNO-W            <ATHB37> 170213 
 2223.00            MOVE ZSCLABCK-CHDRNUM        TO WSAA-ACMV-CHDRNUM            <ATHB37> 170213 
 2224.00            MOVE '01'                   TO WSAA-ACMV-LIFE                <ATHB37> 170213 
 2225.00            MOVE '01'                   TO WSAA-ACMV-COVERAGE            <ATHB37> 170213 
 2226.00            MOVE '00'                   TO WSAA-ACMV-RIDER               <ATHB37> 170213 
 2227.00            MOVE '00'                   TO WSAA-ACMV-PLAN-SUFF           <ATHB37> 170213 
 2228.00                                                                         <ATHB37> 170213 
 2229.00            INITIALIZE ACMVBK3-PARAMS                                    <ATHB37> 170213 
 2230.00            INITIALIZE ACMVBK3REC-KEY-DATA     OF ACMVBK3-PARAMS         <ATHB37> 170213 
 2231.00            INITIALIZE ACMVBK3REC-NON-KEY-DATA OF ACMVBK3-PARAMS         <ATHB37> 170213 
 2232.00            MOVE ZSCLABCK-CHDRCOY       TO ACMVBK3-RLDGCOY               <ATHB37> 170213 
 2233.00            MOVE WSAA-ACMV-RLDGACCT     TO ACMVBK3-RLDGACCT              <ATHB37> 170213 
 2234.00            MOVE WSCC-LE                TO ACMVBK3-SACSCODE              <ATHB37> 170213 
 2235.00            MOVE WSCC-YC                TO ACMVBK3-SACSTYP               <ATHB37> 170213 
 2236.00            MOVE BEGN                   TO ACMVBK3-FUNCTION              <ATHB37> 170213 
 2237.00            PERFORM X1100-ACMVBK3-IO                                     <ATHB37> 170213 
 2238.00            PERFORM                                                      <ATHB37> 170213 
 2239.00              UNTIL ACMVBK3-STATUZ       = ENDP                          <ATHB37> 170213 
 2240.00                                                                         <ATHB37> 170213 
 2241.00                 MOVE 'B522'            TO WSAA-BATCTRCDE                <ATHB37> 170213 
 2242.00                 PERFORM X2200-READ-PTRNREV                              <ATHB37> 170213 
 2243.00                                                                         <ATHB37> 170213 
 2244.00                 IF  VALID-RECORD                                        <ATHB37> 170213 
 2245.00                 IF  ACMVBK3-EFFDATE    >= WSAA-OCCDATE                  <ATHB37> 170213 
 2246.00                 AND ACMVBK3-EFFDATE    <  WSAA-NEXT-ANNI-DATE           <ATHB37> 170213 
 2247.00                                                                         <ATHB37> 170213 
 2248.00                     PERFORM 2250A-LOAD-ARRAY-ACMV                       <ATHB37> 170213 
 2249.00                                                                         <ATHB37> 170213 
 2250.00                     MOVE ACMVBK3-TRANREF(1:8)                           <ATHB37> 170213 
 2251.00                                         TO WSAA-ACMV-AGNTNUM            <ATHB37> 170213 
 2252.00                                           (WSAA-ACMV-ARRAY-CNT)         <ATHB37> 170213 
 2253.00                     ADD ACMVBK3-ORIGAMT TO WSAA-ACMV-ZPREMAMT           <ATHB37> 170213 
 2254.00                                           (WSAA-ACMV-ARRAY-CNT)         <ATHB37> 170213 
 2255.00                                                                         <ATHB37> 170213 
 2256.00                     COMPUTE WSAA-PAID-PREM                              <ATHB37> 170213 
 2257.00                                         = WSAA-PAID-PREM                <ATHB37> 170213 
 2258.00                                         + ACMVBK3-ORIGAMT               <ATHB37> 170213 
 2259.00                     IF  ACMVBK3-TRANNO NOT = WSAA-LAST-TRANNO           <ATHB37> 170213 
 2260.00                     PERFORM  2255-FIND-COMMISSIONS                      <ATHB37> 170213 
 2261.00                     END-IF                                              <ATHB37> 170213 
 2262.00                     MOVE ACMVBK3-TRANNO TO WSAA-LAST-TRANNO             <ATHB37> 170213 
 2263.00                 END-IF                                                  <ATHB37> 170213 
 2264.00                 END-IF                                                  <ATHB37> 170213 
 2265.00                                                                         <ATHB37> 170213 
 2266.00                 MOVE NEXTR             TO ACMVBK3-FUNCTION              <ATHB37> 170213 
 2267.00                 PERFORM X1100-ACMVBK3-IO                                <ATHB37> 170213 
 2268.00            END-PERFORM                                                  <ATHB37> 170213 
 2269.00                                                                         <ATHB37> 170213 
 2270.00            .                                                            <ATHB37> 170213 
 2271.00        2865-EXIT.                                                       <ATHB37> 170213 
 2272.00            EXIT.                                                        <ATHB37> 170213 
 2273.00       /                                                                 <ATHB37> 170213 
 2274.00        2868-CALC-COMM SECTION.                                          <ATHB37> 170214 
 2275.00       ************************                                          <ATHB37> 170214 
 2276.00        2868-START.                                                      <ATHB37> 170213 
 2277.00                                                                         <ATHD11> 181019 
 2278.00            PERFORM X4250-READ-T8Z05                                     <ATHD11> 181019 
 2279.00                                                                         <ATHB37> 170214 
 2280.00            IF MCPPI-PRODUCT                                             <ATHD11> 181019 
 2281.00               MOVE AGCMBCR-RNWCPY     TO WSAA-METHOD-IT                 <ATHB37> 181019 
 2282.00               MOVE COVRAFI-CRTABLE    TO WSAA-CRTABLE-IT                <ATHB37> 181019 
 2283.00               PERFORM X4100-READ-T7Z11                                  <ATHB37> 181019 
 2284.00               PERFORM X4150-GET-T7Z11                                   <ATHB37> 181019 
 2285.00               MOVE WSAA-T7Z11         TO WSAA-COMM-RATE                 <ATHD11> 181019 
 2286.00            ELSE                                                         <ATHD11> 181019 
 2287.00               MOVE COVRAFI-CRTABLE    TO WSAA-READ-CRTABLE              <ATHD11> 181019 
 2288.00               PERFORM X4700-READ-T5687                                  <ATHD11> 181019 
 2289.00               MOVE T5687-RNWCPY       TO WSAA-METHOD-IT                 <ATHD11> 181019 
 2290.00               PERFORM X4300-READ-T5694                                  <ATHD11> 181019 
 2291.00               MOVE 1                  TO WSAA-TERMW                     <ATHD11> 181019 
 2292.00               PERFORM X4350-GET-T5694                                   <ATHD11> 181019 
 2293.00               VARYING WSAA-INDEX        FROM 1                          <ATHD11> 181019 
 2294.00                                           BY 1                          <ATHD11> 181019 
 2295.00                                         UNTIL WSAA-INDEX > 11           <ATHD11> 181019 
 2296.00               MOVE WSAA-T5694         TO WSAA-COMM-RATE                 <ATHD11> 181019 
 2297.00            END-IF                                                       <ATHD11> 181019 
 2298.00                                                                         <ATHD11> 181019 
 2299.00            COMPUTE WSAA-PAID-COMM-CLAWB ROUNDED                         <ATHB37> 170215 
 2300.00                                        = WSAA-PAID-PREM-CLAWB           <ATHB37> 170214 
 2301.00                                        * (WSAA-COMM-RATE                <ATHD11> 181019 
 2302.00                                        / 100)                           <ATHB37> 170214 
 2303.00            .                                                            <ATHB37> 170214 
 2304.00        2868-EXIT.                                                       <ATHB37> 170213 
 2305.00            EXIT.                                                        <ATHB37> 170213 
 2306.00       /                                                                 <ATHB37> 170214 
 2307.00        2869-CALC-OVRCOM SECTION.                                        <ATHB37> 170214 
 2308.00       **************************                                        <ATHB37> 170214 
 2309.00        2869-START.                                                      <ATHB37> 170214 
 2310.00                                                                         <ATHB37> 170214 
 2311.00            PERFORM X4200-READ-T5Z01                                     <ATHB37> 170214 
 2312.00            MOVE T5Z01-ZAACPY          TO WSAA-METHOD-IT                 <ATHB37> 181019 
 2313.00       **   MOVE COVRAFI-CRTABLE       TO WSAA-CRTABLE-IT                <ATHB37> 170302 
 2314.00            PERFORM X4300-READ-T5694                                     <ATHB37> 170302 
 2315.00            MOVE 1                     TO WSAA-TERMW                     <ATHB37> 170302 
 2316.00            PERFORM X4350-GET-T5694                                      <ATHB37> 170302 
 2317.00            VARYING WSAA-INDEX        FROM 1                             <ATHB37> 170302 
 2318.00                                        BY 1                             <ATHB37> 170302 
 2319.00                                     UNTIL WSAA-INDEX > 11               <ATHB37> 170302 
 2320.00                                                                         <ATHB37> 170214 
 2321.00            COMPUTE WSAA-PAID-OVRCOM-CLAWB ROUNDED                       <ATHB37> 170215 
 2322.00                                        = WSAA-PAID-PREM-CLAWB           <ATHB37> 170214 
 2323.00                                        * (WSAA-T5694                    <ATHB37> 170302 
 2324.00                                        / 100)                           <ATHB37> 170214 
 2325.00            .                                                            <ATHB37> 170214 
 2326.00        2869-EXIT.                                                       <ATHB37> 170214 
 2327.00            EXIT.                                                        <ATHB37> 170214 
 2328.00       /                                                                          151104 
 2329.00        3000-TERMINATION SECTION.                                                 151104 
 2330.00       **************************                                                 151104 
 2331.00        3000-START.                                                               151104 
 2332.00                                                                                  151104 
 2333.00             IF  ZSCLABCK-FUNCTION       = WSCC-DECRP                    <ATHB37> 170215 
 2334.00                 MOVE WSAA-CLAW-COMM-REMN                                <ATHB37> 170215 
 2335.00                                        TO ZSCLABCK-COMM-REGP            <ATHB37> 170215 
 2336.00                 MOVE WSAA-PREM-CLAWB   TO ZSCLABCK-PREM-REGP            <ATHB37> 170215 
 2337.00             ELSE                                                        <ATHB37> 170215 
 2338.00             MOVE WSAA-PAID-COMM-CLAWB  TO ZSCLABCK-COMM-REGP                     151109 
 2339.00             MOVE WSAA-TOT-CLAWB-TOPUP  TO ZSCLABCK-COMM-TOPUP                    151109 
 2340.00             END-IF                                                      <ATHB37> 170215 
 2341.00                                                                                  151104 
 2342.00            MOVE O-K                    TO ZSCLABCK-STATUZ                        151104 
 2343.00            .                                                                     151104 
 2344.00        3000-EXIT.                                                                151104 
 2345.00            EXIT.                                                                 151104 
 2346.00                                                                                  151030 
 2347.00       /                                                                          151030 
 2348.00        9000-FATAL-ERROR SECTION.                                                 151030 
 2349.00       **************************                                                 151030 
 2350.00        9000-START.                                                               151030 
 2351.00                                                                                  151030 
 2352.00            MOVE WSAA-SUBR              TO SYSR-SUBRNAME                          151030 
 2353.00            MOVE SYSR-STATUZ            TO ZSCLABCK-STATUZ                        151109 
 2354.00                                                                                  151030 
 2355.00            IF  SYSR-SYSERR-TYPE     NOT = WSCC-TXT-2                             151030 
 2356.00                MOVE WSCC-TXT-1         TO SYSR-SYSERR-TYPE                       151030 
 2357.00            END-IF                                                                151030 
 2358.00                                                                                  151030 
 2359.00            CALL 'SYSERR'            USING SYSR-SYSERR-REC                        151030 
 2360.00            .                                                                     151030 
 2361.00        9000-EXIT.                                                                151030 
 2362.00            GOBACK.                                                               151030 
 2363.00       /                                                                          151112 
 2364.00        X100-ITEM-IO SECTION.                                                     151112 
 2365.00       **********************                                                     151112 
 2366.00        X100-START.                                                               151112 
 2367.00                                                                                  151112 
 2368.00            MOVE ITEMREC                TO ITEM-FORMAT                            151112 
 2369.00                                                                                  151112 
 2370.00            CALL 'ITEMIO'            USING ITEM-PARAMS                            151112 
 2371.00                                                                                  151112 
 2372.00            IF  ITEM-STATUZ          NOT = O-K                                    151112 
 2373.00                MOVE ITEM-PARAMS        TO SYSR-PARAMS                            151112 
 2374.00                MOVE ITEM-STATUZ        TO SYSR-STATUZ                            151112 
 2375.00                PERFORM 9000-FATAL-ERROR                                          151112 
 2376.00            END-IF                                                                151112 
 2377.00            .                                                                     151112 
 2378.00        X100-EXIT.                                                                151112 
 2379.00             EXIT.                                                                151112 
 2380.00       /                                                                          151030 
 2381.00        X200-ZTUD-IO SECTION.                                                     151030 
 2382.00       *************************                                                  151030 
 2383.00        X200-START.                                                               151030 
 2384.00                                                                                  151030 
 2385.00            MOVE ZTUDREC                TO ZTUD-FORMAT                            151030 
 2386.00            CALL 'ZTUDIO'            USING ZTUD-PARAMS.                           151030 
 2387.00                                                                                  151030 
 2388.00            EVALUATE ZTUD-FUNCTION                                                151109 
 2389.00            WHEN  BEGN                                                            151109 
 2390.00                  IF  ZTUD-STATUZ NOT = O-K                                       151109 
 2391.00                  AND ZTUD-STATUZ NOT = ENDP                                      151109 
 2392.00                      MOVE ZTUD-PARAMS         TO SYSR-PARAMS                     151109 
 2393.00                      PERFORM 9000-FATAL-ERROR                                    151109 
 2394.00                  END-IF                                                          151109 
 2395.00                  IF  ZTUD-CHDRCOY   NOT = ZSCLABCK-CHDRCOY                       151109 
 2396.00                  OR  ZTUD-CHDRNUM   NOT = ZSCLABCK-CHDRNUM                       151109 
 2397.00                      MOVE ENDP         TO ZTUD-STATUZ                            151109 
 2398.00                  END-IF                                                          151109 
 2399.00            WHEN  NEXTR                                                           151109 
 2400.00                  IF  ZTUD-STATUZ NOT = O-K                                       151109 
 2401.00                  AND ZTUD-STATUZ NOT = ENDP                                      151109 
 2402.00                      MOVE ZTUD-PARAMS         TO SYSR-PARAMS                     151109 
 2403.00                      PERFORM 9000-FATAL-ERROR                                    151109 
 2404.00                  END-IF                                                          151109 
 2405.00                  IF  ZTUD-CHDRCOY   NOT = ZSCLABCK-CHDRCOY                       151109 
 2406.00                  OR  ZTUD-CHDRNUM   NOT = ZSCLABCK-CHDRNUM                       151109 
 2407.00                      MOVE ENDP         TO ZTUD-STATUZ                            151109 
 2408.00                  END-IF                                                          151109 
 2409.00            WHEN  WRITR                                                           151109 
 2410.00                  IF  ZTUD-STATUZ NOT = O-K                                       151109 
 2411.00                      MOVE ZTUD-PARAMS         TO SYSR-PARAMS                     151109 
 2412.00                      PERFORM 9000-FATAL-ERROR                                    151109 
 2413.00                  END-IF                                                          151109 
 2414.00            END-EVALUATE                                                          151109 
 2415.00            .                                                                     151030 
 2416.00        X200-EXIT.                                                                151030 
 2417.00            EXIT.                                                                 151030 
 2418.00       /                                                                          151104 
 2419.00        X300-AGCMBCR-IO SECTION.                                                  151104 
 2420.00       *************************                                                  151104 
 2421.00        X300-START.                                                               151104 
 2422.00                                                                                  151104 
 2423.00            MOVE O-K                    TO AGCMBCR-STATUZ                         151104 
 2424.00            MOVE AGCMBCRREC             TO AGCMBCR-FORMAT                         151104 
 2425.00                                                                                  151104 
 2426.00            CALL 'AGCMBCRIO'         USING AGCMBCR-PARAMS                         151104 
 2427.00                                                                                  151104 
 2428.00            IF  AGCMBCR-STATUZ       NOT = O-K                                    151104 
 2429.00            AND AGCMBCR-STATUZ       NOT = ENDP                                   151104 
 2430.00               MOVE AGCMBCR-PARAMS      TO SYSR-PARAMS                            151104 
 2431.00               MOVE AGCMBCR-STATUZ      TO SYSR-STATUZ                            151104 
 2432.00               PERFORM 9000-FATAL-ERROR                                           151104 
 2433.00            END-IF                                                                151104 
 2434.00                                                                                  151104 
 2435.00            IF  AGCMBCR-CHDRCOY      NOT = ZSCLABCK-CHDRCOY                       151104 
 2436.00            OR  AGCMBCR-CHDRNUM      NOT = ZSCLABCK-CHDRNUM                       151104 
 2437.00            OR  AGCMBCR-LIFE         NOT = WSCC-01                                151104 
 2438.00            OR  AGCMBCR-COVERAGE     NOT = WSCC-01                                151104 
 2439.00            OR  AGCMBCR-RIDER        NOT = WSCC-00                                151104 
 2440.00                MOVE ENDP               TO AGCMBCR-STATUZ                         151104 
 2441.00            END-IF                                                                151104 
 2442.00            .                                                                     151104 
 2443.00        X300-EXIT.                                                                151104 
 2444.00            EXIT.                                                                 151104 
 2445.00       /                                                                          151104 
 2446.00        X400-ZCHD-IO SECTION.                                                     151104 
 2447.00       *************************                                                  151104 
 2448.00        X400-START.                                                               151104 
 2449.00                                                                                  151104 
 2450.00            MOVE O-K                 TO ZCHD-STATUZ                               151104 
 2451.00            MOVE ZCHDREC             TO ZCHD-FORMAT                               151104 
 2452.00            CALL 'ZCHDIO'         USING ZCHD-PARAMS                               151104 
 2453.00                                                                                  151104 
 2454.00            IF  ZCHD-STATUZ       NOT = O-K                                       151104 
 2455.00            AND ZCHD-STATUZ       NOT = MRNF                                      151104 
 2456.00               MOVE ZCHD-PARAMS      TO SYSR-PARAMS                               151104 
 2457.00               MOVE ZCHD-STATUZ      TO SYSR-STATUZ                               151104 
 2458.00               PERFORM 9000-FATAL-ERROR                                           151104 
 2459.00            END-IF                                                                151104 
 2460.00            .                                                                     151104 
 2461.00        X400-EXIT.                                                                151104 
 2462.00            EXIT.                                                                 151104 
 2463.00       /                                                                          151104 
 2464.00        X500-CHDRMJA-IO SECTION.                                                  151104 
 2465.00       *************************                                                  151104 
 2466.00        X500-START.                                                               151104 
 2467.00                                                                                  151104 
 2468.00            MOVE O-K                 TO CHDRMJA-STATUZ                            151104 
 2469.00            MOVE CHDRMJAREC          TO CHDRMJA-FORMAT                            151104 
 2470.00            CALL 'CHDRMJAIO'         USING CHDRMJA-PARAMS                         151104 
 2471.00                                                                                  151104 
 2472.00            IF  CHDRMJA-STATUZ       NOT = O-K                                    151104 
 2473.00            AND CHDRMJA-STATUZ       NOT = MRNF                                   151104 
 2474.00               MOVE CHDRMJA-PARAMS      TO SYSR-PARAMS                            151104 
 2475.00               MOVE CHDRMJA-STATUZ      TO SYSR-STATUZ                            151104 
 2476.00               PERFORM 9000-FATAL-ERROR                                           151104 
 2477.00            END-IF                                                                151104 
 2478.00            .                                                                     151104 
 2479.00        X500-EXIT.                                                                151104 
 2480.00            EXIT.                                                                 151104 
 2481.00       /                                                                          151109 
 2482.00        X600-READ-AGNT  SECTION.                                                  151109 
 2483.00       ***********************************                                        151109 
 2484.00        X600-START.                                                               151109 
 2485.00                                                                                  151109 
 2486.00            INITIALIZE AGNTREC-KEY-DATA     OF AGNT-PARAMS                        151109 
 2487.00            INITIALIZE AGNTREC-NON-KEY-DATA OF AGNT-PARAMS                        151109 
 2488.00                                                                                  151109 
 2489.00            MOVE WSCC-AG                TO AGNT-AGNTPFX                           151109 
 2490.00            MOVE ZSCLABCK-CHDRCOY       TO AGNT-AGNTCOY                           151109 
 2491.00            MOVE WSAA-AGNTNUM           TO AGNT-AGNTNUM                           151123 
 2492.00            MOVE READR                  TO AGNT-FUNCTION                          151109 
 2493.00                                                                                  151109 
 2494.00            PERFORM X650-AGNT-IO                                                  151109 
 2495.00                                                                                  151109 
 2496.00            .                                                                     151109 
 2497.00        X600-EXIT.                                                                151109 
 2498.00            EXIT.                                                                 151109 
 2499.00       /                                                                          151109 
 2500.00        X650-AGNT-IO SECTION.                                                     151109 
 2501.00       *************************                                                  151109 
 2502.00        X650-START.                                                               151109 
 2503.00                                                                                  151109 
 2504.00            MOVE O-K                 TO AGNT-STATUZ                               151109 
 2505.00            MOVE AGNTREC          TO AGNT-FORMAT                                  151109 
 2506.00            CALL 'AGNTIO'         USING AGNT-PARAMS                               151109 
 2507.00                                                                                  151109 
 2508.00            IF  AGNT-STATUZ       NOT = O-K                                       151109 
 2509.00            AND AGNT-STATUZ       NOT = MRNF                                      151109 
 2510.00               MOVE AGNT-PARAMS      TO SYSR-PARAMS                               151109 
 2511.00               MOVE AGNT-STATUZ      TO SYSR-STATUZ                               151109 
 2512.00               PERFORM 9000-FATAL-ERROR                                           151109 
 2513.00            END-IF                                                                151109 
 2514.00            .                                                                     151109 
 2515.00        X650-EXIT.                                                                151109 
 2516.00            EXIT.                                                                 151109 
 2517.00       /                                                                          151106 
 2518.00        X800-ACMVREV-IO SECTION.                                                  151106 
 2519.00       ************************                                                   151106 
 2520.00        X800-START.                                                               151106 
 2521.00                                                                                  151106 
 2522.00            MOVE O-K                    TO ACMVREV-STATUZ                         151106 
 2523.00            MOVE ACMVREVREC             TO ACMVREV-FORMAT                         151106 
 2524.00                                                                                  151106 
 2525.00            CALL 'ACMVREVIO'         USING ACMVREV-PARAMS                         151106 
 2526.00                                                                                  151106 
 2527.00            IF  ACMVREV-STATUZ       NOT = O-K                                    151106 
 2528.00            AND ACMVREV-STATUZ       NOT = ENDP                                   151106 
 2529.00                MOVE ACMVREV-STATUZ     TO SYSR-STATUZ                            151106 
 2530.00                MOVE ACMVREV-PARAMS     TO SYSR-PARAMS                            151106 
 2531.00                PERFORM 9000-FATAL-ERROR                                          151109 
 2532.00            END-IF                                                                151106 
 2533.00                                                                                  151106 
 2534.00            IF  ACMVREV-RLDGCOY      NOT = ACMVBK3-RLDGCOY                        151109 
 2535.00            OR  ACMVREV-RDOCNUM      NOT = ACMVBK3-RDOCNUM                        151109 
 2536.00            OR  ACMVREV-TRANNO       NOT = ACMVBK3-TRANNO                         151109 
 2537.00                MOVE ENDP               TO ACMVREV-STATUZ                         151106 
 2538.00            END-IF                                                                151106 
 2539.00            .                                                                     151106 
 2540.00        X800-EXIT.                                                                151106 
 2541.00            EXIT.                                                                 151106 
 2542.00       /                                                                          151118 
 2543.00        X800A-ACMVREV-IO SECTION.                                                 151118 
 2544.00       ************************                                                   151118 
 2545.00        X800A-START.                                                              151118 
 2546.00                                                                                  151118 
 2547.00            MOVE O-K                    TO ACMVREV-STATUZ                         151118 
 2548.00            MOVE ACMVREVREC             TO ACMVREV-FORMAT                         151118 
 2549.00                                                                                  151118 
 2550.00            CALL 'ACMVREVIO'         USING ACMVREV-PARAMS                         151118 
 2551.00                                                                                  151118 
 2552.00            IF  ACMVREV-STATUZ       NOT = O-K                                    151118 
 2553.00            AND ACMVREV-STATUZ       NOT = ENDP                                   151118 
 2554.00                MOVE ACMVREV-STATUZ     TO SYSR-STATUZ                            151118 
 2555.00                MOVE ACMVREV-PARAMS     TO SYSR-PARAMS                            151118 
 2556.00                PERFORM 9000-FATAL-ERROR                                          151118 
 2557.00            END-IF                                                                151118 
 2558.00                                                                                  151118 
 2559.00            IF  ACMVREV-RLDGCOY      NOT = ZTUD-CHDRCOY                           151118 
 2560.00            OR  ACMVREV-RDOCNUM      NOT = ZTUD-CHDRNUM                           151118 
 2561.00            OR  ACMVREV-TRANNO       NOT = ZTUD-TRANNO                            151118 
 2562.00                MOVE ENDP               TO ACMVREV-STATUZ                         151118 
 2563.00            END-IF                                                                151118 
 2564.00            .                                                                     151118 
 2565.00        X800A-EXIT.                                                               151118 
 2566.00            EXIT.                                                                 151118 
 2567.00       /                                                                          151108 
 2568.00        X900-CLAWBACK-RULES-PERC SECTION.                                         151108 
 2569.00       ***********************************                                        151108 
 2570.00        X900-START.                                                               151108 
 2571.00                                                                                  151108 
 2572.00       *    IF  CHDRMJA-BILLFREQ   NOT  = '00'                                    151123 
 2573.00                                                                                  151108 
 2574.00            MOVE WSAA-FROM-DATE         TO DTC3-INT-DATE-1                        151108 
 2575.00            MOVE ZSCLABCK-EFFDATE       TO DTC3-INT-DATE-2                        151108 
 2576.00                                                                         <ATHB37> 170208 
 2577.00            IF  ZSCLABCK-FUNCTION        = WSCC-DECRP                    <ATHB37> 170208 
 2578.00                MOVE WSAA-FROM-DATE-W(WSAA-COUNT-YEAR)                   <ATHB37> 170208 
 2579.00                                        TO DTC3-INT-DATE-2               <ATHB37> 170208 
 2580.00            END-IF                                                       <ATHB37> 170208 
 2581.00                                                                         <ATHB37> 170208 
 2582.00            MOVE '01'                   TO DTC3-FREQUENCY                         151108 
 2583.00            CALL 'DATCON3'           USING DTC3-DATCON3-REC                       151108 
 2584.00                                                                                  151108 
 2585.00            IF  DTC3-STATUZ          NOT = O-K                                    151108 
 2586.00                MOVE DTC3-DATCON3-REC   TO SYSR-PARAMS                            151108 
 2587.00                MOVE DTC3-STATUZ        TO SYSR-STATUZ                            151108 
 2588.00                PERFORM 9000-FATAL-ERROR                                          151108 
 2589.00            END-IF                                                                151108 
 2590.00            COMPUTE WSAA-TERM            = DTC3-FREQ-FACTOR                       151108 
 2591.00                                         + 0.99999                                151108 
 2592.00                                         + 0.00001                                151223 
 2593.00            END-COMPUTE                                                           151108 
 2594.00                                                                                  151108 
 2595.00       *    ELSE                                                                  151123 
 2596.00       *        MOVE 0                  TO WSAA-TERM                              151123 
 2597.00       *    END-IF                                                                151123 
 2598.00                                                                                  151108 
 2599.00            MOVE 0                      TO WSAA-T8Z82                             151108 
 2600.00                                                                                  151108 
 2601.00            PERFORM X950-GET-T8Z82                                                151108 
 2602.00            VARYING WSAA-INDEX        FROM 1                                      151108 
 2603.00                                        BY 1                                      151108 
 2604.00                                     UNTIL WSAA-INDEX > 11                        151108 
 2605.00            .                                                                     151108 
 2606.00        X900-EXIT.                                                                151108 
 2607.00            EXIT.                                                                 151108 
 2608.00       /                                                                 <ATHA67> 160407 
 2609.00        X900A-CLAWBACK-RULES-PERC-TOP SECTION.                           <ATHA67> 160407 
 2610.00       ***********************************                               <ATHA67> 160407 
 2611.00        X900A-START.                                                     <ATHA67> 160407 
 2612.00                                                                         <ATHA67> 160407 
 2613.00            IF  CHDRMJA-BILLFREQ        = '00'                           <ATHA67> 160407 
 2614.00                MOVE 0                  TO WSAA-TERM                     <ATHA67> 160407 
 2615.00                GO TO X900A-EXIT                                         <ATHA67> 160407 
 2616.00            END-IF                                                       <ATHA67> 160407 
 2617.00                                                                         <ATHA67> 160407 
 2618.00            MOVE WSAA-FROM-DATE         TO DTC3-INT-DATE-1               <ATHA67> 160407 
 2619.00            MOVE ZSCLABCK-EFFDATE       TO DTC3-INT-DATE-2               <ATHA67> 160407 
 2620.00            MOVE '01'                   TO DTC3-FREQUENCY                <ATHA67> 160407 
 2621.00            CALL 'DATCON3'           USING DTC3-DATCON3-REC              <ATHA67> 160407 
 2622.00                                                                         <ATHA67> 160407 
 2623.00            IF  DTC3-STATUZ          NOT = O-K                           <ATHA67> 160407 
 2624.00                MOVE DTC3-DATCON3-REC   TO SYSR-PARAMS                   <ATHA67> 160407 
 2625.00                MOVE DTC3-STATUZ        TO SYSR-STATUZ                   <ATHA67> 160407 
 2626.00                PERFORM 9000-FATAL-ERROR                                 <ATHA67> 160407 
 2627.00            END-IF                                                       <ATHA67> 160407 
 2628.00            COMPUTE WSAA-TERM            = DTC3-FREQ-FACTOR              <ATHA67> 160407 
 2629.00                                         + 0.99999                       <ATHA67> 160407 
 2630.00                                         + 0.00001                       <ATHA67> 160407 
 2631.00            END-COMPUTE                                                  <ATHA67> 160407 
 2632.00                                                                         <ATHA67> 160407 
 2633.00            MOVE 0                      TO WSAA-T8Z82                    <ATHA67> 160407 
 2634.00                                                                         <ATHA67> 160407 
 2635.00            PERFORM X950-GET-T8Z82                                       <ATHA67> 160407 
 2636.00            VARYING WSAA-INDEX        FROM 1                             <ATHA67> 160407 
 2637.00                                        BY 1                             <ATHA67> 160407 
 2638.00                                     UNTIL WSAA-INDEX > 11               <ATHA67> 160407 
 2639.00            .                                                            <ATHA67> 160407 
 2640.00        X900A-EXIT.                                                      <ATHA67> 160407 
 2641.00            EXIT.                                                        <ATHA67> 160407 
 2642.00       /                                                                          151108 
 2643.00        X950-GET-T8Z82 SECTION.                                                   151108 
 2644.00       ************************                                                   151108 
 2645.00        X950-START.                                                               151108 
 2646.00                                                                                  151108 
 2647.00       *  Access table value based on WSAA-TERM                                   151108 
 2648.00                                                                                  151108 
 2649.00            IF  WSAA-TERM            NOT > T8Z82-TO-YEAR(WSAA-INDEX)              151108 
 2650.00                MOVE T8Z82-INSTALPC(WSAA-INDEX)                                   151108 
 2651.00                                        TO WSAA-T8Z82                             151108 
 2652.00                MOVE 13                 TO WSAA-INDEX                             151108 
 2653.00            END-IF                                                                151108 
 2654.00            .                                                                     151108 
 2655.00        X950-EXIT.                                                                151108 
 2656.00            EXIT.                                                                 151108 
 2657.00       /                                                                          151030 
 2658.00        X1100-ACMVBK3-IO SECTION.                                                 151030 
 2659.00       **************************                                                 151030 
 2660.00        X1100-START.                                                              151030 
 2661.00                                                                                  151030 
 2662.00            MOVE O-K                    TO ACMVBK3-STATUZ                         151030 
 2663.00            MOVE ACMVBK3REC             TO ACMVBK3-FORMAT                         151030 
 2664.00                                                                                  151030 
 2665.00            CALL 'ACMVBK3IO'         USING ACMVBK3-PARAMS                         151030 
 2666.00                                                                                  151030 
 2667.00            IF  ACMVBK3-STATUZ       NOT = O-K                                    151030 
 2668.00            AND ACMVBK3-STATUZ       NOT = ENDP                                   151030 
 2669.00                MOVE ACMVBK3-STATUZ     TO SYSR-STATUZ                            151030 
 2670.00                MOVE ACMVBK3-PARAMS     TO SYSR-PARAMS                            151030 
 2671.00                PERFORM 9000-FATAL-ERROR                                          151030 
 2672.00            END-IF                                                                151030 
 2673.00                                                                                  151030 
 2674.00            IF  ACMVBK3-RLDGCOY      NOT = ZSCLABCK-CHDRCOY                       151109 
 2675.00            OR  ACMVBK3-RLDGACCT     NOT = WSAA-ACMV-RLDGACCT                     151030 
 2676.00            OR  ACMVBK3-SACSTYP      NOT = WSCC-YC                                151110 
 2677.00            OR  ACMVBK3-SACSCODE     NOT = WSCC-LE                                151030 
 2678.00                MOVE ENDP               TO ACMVBK3-STATUZ                         151030 
 2679.00            END-IF                                                                151030 
 2680.00            .                                                                     151030 
 2681.00        X1100-EXIT.                                                               151030 
 2682.00            EXIT.                                                                 151030 
 2683.00       /                                                                          151030 
 2684.00        X1150-ACMVBK3-IO SECTION.                                                 151122 
 2685.00       *****************************                                              151030 
 2686.00        X1150-START.                                                              151030 
 2687.00                                                                                  151030 
 2688.00            MOVE O-K                    TO ACMVBK3-STATUZ                         151030 
 2689.00            MOVE ACMVBK3REC             TO ACMVBK3-FORMAT                         151030 
 2690.00                                                                                  151030 
 2691.00            CALL 'ACMVBK3IO'         USING ACMVBK3-PARAMS                         151030 
 2692.00                                                                                  151030 
 2693.00            IF  ACMVBK3-STATUZ       NOT = O-K                                    151030 
 2694.00            AND ACMVBK3-STATUZ       NOT = ENDP                                   151030 
 2695.00                MOVE ACMVBK3-STATUZ     TO SYSR-STATUZ                            151030 
 2696.00                MOVE ACMVBK3-PARAMS     TO SYSR-PARAMS                            151030 
 2697.00                PERFORM 9000-FATAL-ERROR                                          151030 
 2698.00            END-IF                                                                151030 
 2699.00                                                                                  151030 
 2700.00            IF  ACMVBK3-RLDGCOY      NOT = ZSCLABCK-CHDRCOY                       151109 
 2701.00            OR  ACMVBK3-RLDGACCT     NOT = WSAA-ACMV-RLDGACCT                     151030 
 2702.00       **   OR  ACMVBK3-SACSTYP      NOT = WSCC-PS                                151122 
 2703.00       **   OR  ACMVBK3-SACSCODE     NOT = WSCC-LE                                151122 
 2704.00                MOVE ENDP               TO ACMVBK3-STATUZ                         151030 
 2705.00            END-IF                                                                151030 
 2706.00            .                                                                     151030 
 2707.00        X1150-EXIT.                                                               151030 
 2708.00            EXIT.                                                                 151030 
 2709.00       /                                                                          151110 
 2710.00        X1250-ZTUH-IO SECTION.                                                    151110 
 2711.00       **************************                                                 151110 
 2712.00        X1250-START.                                                              151110 
 2713.00                                                                                  151110 
 2714.00            MOVE O-K                    TO ZTUH-STATUZ                            151110 
 2715.00            MOVE ZTUHREC             TO ZTUH-FORMAT                               151110 
 2716.00                                                                                  151110 
 2717.00            CALL 'ZTUHIO'         USING ZTUH-PARAMS                               151110 
 2718.00                                                                                  151110 
 2719.00            IF  ZTUH-STATUZ       NOT = O-K                                       151110 
 2720.00            AND ZTUH-STATUZ       NOT = MRNF                                      151110 
 2721.00                MOVE ZTUH-STATUZ     TO SYSR-STATUZ                               151110 
 2722.00                MOVE ZTUH-PARAMS     TO SYSR-PARAMS                               151110 
 2723.00                PERFORM 9000-FATAL-ERROR                                          151110 
 2724.00            END-IF                                                                151110 
 2725.00                                                                                  151110 
 2726.00            .                                                                     151110 
 2727.00        X1250-EXIT.                                                               151110 
 2728.00            EXIT.                                                                 151110 
 2729.00       /                                                                 <ATHA39> 151110 
 2730.00        X1270-WRITE-ZTUHTRN SECTION.                                              151110 
 2731.00       *****************************                                     <ATHA39> 151110 
 2732.00        X1270-START.                                                     <ATHA39> 151110 
 2733.00            INITIALIZE ZTUHTRN-PARAMS                                             151110 
 2734.00            INITIALIZE ZTUHTRNREC-KEY-DATA  OF ZTUHTRN-PARAMS                     151110 
 2735.00            INITIALIZE ZTUHTRNREC-NON-KEY-DATA OF ZTUHTRN-PARAMS                  151110 
 2736.00                                                                         <ATHA39> 151110 
 2737.00            MOVE ZTUH-CHDRCOY           TO ZTUHTRN-CHDRCOY                        151110 
 2738.00            MOVE ZTUH-CHDRNUM           TO ZTUHTRN-CHDRNUM                        151110 
 2739.00            MOVE ZTUH-RECODE            TO ZTUHTRN-RECODE                         151110 
 2740.00            MOVE ZSCLABCK-TRANNO        TO ZTUHTRN-TRANNO                         151110 
 2741.00            MOVE ZSCLABCK-EFFDATE       TO ZTUHTRN-PRCDATE                        151110 
 2742.00            MOVE ZTUH-EFFDATE           TO ZTUHTRN-EFFDATE                        151123 
 2743.00            MOVE ZTUH-CNTTYPE           TO ZTUHTRN-CNTTYPE                        151123 
 2744.00            MOVE ZTUH-CRTABLE           TO ZTUHTRN-CRTABLE                        151123 
 2745.00            MOVE ZTUH-JSTATUS           TO ZTUHTRN-JSTATUS                        151208 
 2746.00            IF  ZSCLABCK-FUNCTION        = WSCC-SURFS                             151208 
 2747.00            MOVE WSCC-SU                TO ZTUHTRN-JSTATUS                        151208 
 2748.00            END-IF                                                                151208 
 2749.00            IF  ZSCLABCK-FUNCTION        = WSCC-SURCF                             151208 
 2750.00            MOVE WSCC-CF                TO ZTUHTRN-JSTATUS                        151208 
 2751.00            END-IF                                                                151208 
 2752.00            MOVE ZSCLABCK-EFFDATE       TO ZTUHTRN-STATDATE                       151110 
 2753.00                                                                         <ATHA43> 160323 
 2754.00            IF  ZSCLABCK-FUNCTION        = WSCC-SURFS                    <ATHA43> 160323 
 2755.00            OR  ZSCLABCK-FUNCTION        = WSCC-SURCF                    <ATHA43> 160323 
 2756.00            MOVE ZEROS                  TO ZTUHTRN-ORIG-INST                      151110 
 2757.00            MOVE ZEROS                  TO ZTUHTRN-ZREMPRM                        151110 
 2758.00            ELSE                                                         <ATHC41> 180308 
 2759.00                 MOVE ZTUH-ORIG-INST    TO ZTUHTRN-ORIG-INST             <ATHC41> 180308 
 2760.00                 MOVE ZTUH-ZREMPRM      TO ZTUHTRN-ZREMPRM               <ATHC41> 180308 
 2761.00            END-IF                                                       <ATHA43> 160323 
 2762.00                                                                                  151110 
 2763.00            MOVE WSCC-TXT-1             TO ZTUHTRN-VALIDFLAG                      151110 
 2764.00                                                                         <ATHA39> 151110 
 2765.00            MOVE WRITR                  TO ZTUHTRN-FUNCTION                       151110 
 2766.00            PERFORM X1275-ZTUHTRN-IO                                              151110 
 2767.00            .                                                            <ATHA39> 151110 
 2768.00        X1270-EXIT.                                                      <ATHA39> 151110 
 2769.00            EXIT.                                                        <ATHA39> 151110 
 2770.00       /                                                                 <ATHA39> 151110 
 2771.00        X1275-ZTUHTRN-IO SECTION.                                                 151110 
 2772.00       **************************                                        <ATHA39> 151110 
 2773.00        X1275-START.                                                     <ATHA39> 151110 
 2774.00                                                                         <ATHA39> 151110 
 2775.00            MOVE O-K                    TO ZTUHTRN-STATUZ                         151110 
 2776.00            MOVE ZTUHTRNREC             TO ZTUHTRN-FORMAT                         151110 
 2777.00                                                                         <ATHA39> 151110 
 2778.00            CALL 'ZTUHTRNIO'         USING ZTUHTRN-PARAMS                         151110 
 2779.00                                                                         <ATHA39> 151110 
 2780.00            IF  ZTUHTRN-STATUZ       NOT = O-K                                    151110 
 2781.00                MOVE ZTUHTRN-STATUZ     TO SYSR-STATUZ                            151110 
 2782.00                MOVE ZTUHTRN-PARAMS     TO SYSR-PARAMS                            151110 
 2783.00                PERFORM 9000-FATAL-ERROR                                          151110 
 2784.00            END-IF                                                       <ATHA39> 151110 
 2785.00            .                                                            <ATHA39> 151110 
 2786.00        X1275-EXIT.                                                               151110 
 2787.00            EXIT.                                                        <ATHA39> 151110 
 2788.00       /                                                                 <ATHA39> 151111 
 2789.00        X1400-WRITE-LIFA-REGP SECTION.                                            151111 
 2790.00       *******************************                                   <ATHA39> 151111 
 2791.00        X1400-START.                                                              151111 
 2792.00                                                                                  151116 
 2793.00            MOVE 'IT'                   TO DESC-DESCPFX.                          151116 
 2794.00            MOVE ZSCLABCK-CHDRCOY       TO DESC-DESCCOY.                          151116 
 2795.00            MOVE T5645                  TO DESC-DESCTABL.                         151116 
 2796.00            MOVE 'E'                    TO DESC-LANGUAGE.                         151116 
 2797.00            MOVE 'ZSCLAWBA'             TO DESC-DESCITEM                          151116 
 2798.00            MOVE READR                  TO DESC-FUNCTION.                         151116 
 2799.00            CALL 'DESCIO' USING DESC-PARAMS.                                      151116 
 2800.00            IF DESC-STATUZ              NOT = O-K                                 151116 
 2801.00                MOVE DESC-PARAMS        TO SYSR-PARAMS                            151116 
 2802.00                PERFORM 9000-FATAL-ERROR                                          151116 
 2803.00            END-IF                                                                151116 
 2804.00            MOVE DESC-LONGDESC          TO LIFA-TRANDESC                          151116 
 2805.00       *  Populate LIFA- common fields                                            151111 
 2806.00       *                                                                          151111 
 2807.00            MOVE ZSCLABCK-BATCKEY           TO LIFA-BATCKEY                       151111 
 2808.00            MOVE ZSCLABCK-TRANSACTION-TIME  TO LIFA-TRANSACTION-TIME              151111 
 2809.00            MOVE ZSCLABCK-TRANSACTION-DATE  TO LIFA-TRANSACTION-DATE              151111 
 2810.00            MOVE ZSCLABCK-TERMID            TO LIFA-TERMID                        151111 
 2811.00            MOVE ZSCLABCK-USER              TO LIFA-USER                          151111 
 2812.00            MOVE ZSCLABCK-CHDRNUM           TO LIFA-RDOCNUM                       151111 
 2813.00            MOVE ZSCLABCK-CHDRCOY       TO LIFA-RLDGCOY                           151111 
 2814.00                                           LIFA-GENLCOY                           151111 
 2815.00            MOVE CHDRMJA-CNTCURR        TO LIFA-ORIGCURR                          151111 
 2816.00            MOVE ZSCLABCK-TRANNO        TO LIFA-TRANNO                            151111 
 2817.00            MOVE +0                     TO WSAA-JRNSEQ                            151112 
 2818.00            MOVE 0                      TO LIFA-CRATE                             151111 
 2819.00                                           LIFA-ACCTAMT                           151111 
 2820.00                                           LIFA-RCAMT                             151111 
 2821.00            MOVE SPACES                 TO LIFA-GENLCUR                           151111 
 2822.00                                           LIFA-POSTYEAR                          151111 
 2823.00                                           LIFA-POSTMONTH                         151111 
 2824.00            MOVE ZSCLABCK-EFFDATE       TO LIFA-EFFDATE                           151111 
 2825.00            MOVE VRCM-MAX-DATE          TO LIFA-FRCDATE                           151111 
 2826.00            MOVE CHDRMJA-CNTTYPE        TO LIFA-SUBSTITUTE-CODE(01)               151111 
 2827.00            MOVE +0                     TO WSAA-JRNSEQ                            151111 
 2828.00            .                                                                     151111 
 2829.00        X1400-EXIT.                                                               151111 
 2830.00            EXIT.                                                                 151111 
 2831.00       /                                                                          151111 
 2832.00        X1450-POST-COMM SECTION.                                                  151111 
 2833.00       ************************                                                   151111 
 2834.00        X1450-START.                                                              151111 
 2835.00                                                                                  151111 
 2836.00            MOVE WSAA-T5645-SACSCODE(IX-SA)  TO LIFA-SACSCODE                     151113 
 2837.00            MOVE WSAA-T5645-SACSTYPE(IX-SA)  TO LIFA-SACSTYP                      151113 
 2838.00            MOVE WSAA-T5645-GLMAP   (IX-SA)  TO LIFA-GLCODE                       151113 
 2839.00            MOVE WSAA-T5645-SIGN    (IX-SA)  TO LIFA-GLSIGN                       151113 
 2840.00            MOVE WSAA-T5645-CNTTOT  (IX-SA)  TO LIFA-CONTOT                       151113 
 2841.00                                                                                  151111 
 2842.00            MOVE WSAA-CRTABLE           TO LIFA-SUBSTITUTE-CODE(06)               151111 
 2843.00                                                                                  151111 
 2844.00            ADD +1                      TO WSAA-JRNSEQ                            151111 
 2845.00            MOVE WSAA-JRNSEQ            TO LIFA-JRNSEQ                            151111 
 2846.00                                                                                  151111 
 2847.00            MOVE 'PSTW'                 TO LIFA-FUNCTION                          151111 
 2848.00                                                                                  151111 
 2849.00            CALL 'LIFACMV'           USING LIFA-LIFACMV-REC                       151111 
 2850.00                                                                                  151111 
 2851.00            IF  LIFA-STATUZ          NOT = O-K                                    151111 
 2852.00                MOVE LIFA-LIFACMV-REC   TO SYSR-PARAMS                            151111 
 2853.00                MOVE LIFA-STATUZ        TO SYSR-STATUZ                            151111 
 2854.00                PERFORM 9000-FATAL-ERROR                                          151111 
 2855.00            END-IF                                                                151111 
 2856.00            .                                                                     151111 
 2857.00        X1450-EXIT.                                                               151111 
 2858.00             EXIT.                                                                151111 
 2859.00       /                                                                 <ATHA07> 151110 
 2860.00        X1800-RETRIEVE-ZCHA-AGNTNUM SECTION.                                      151110 
 2861.00       *************************************                                      151110 
 2862.00        X1800-START.                                                              151110 
 2863.00                                                                                  151110 
 2864.00            INITIALIZE ZCHA-PARAMS                                                151110 
 2865.00            INITIALIZE ZCHAREC-KEY-DATA      OF ZCHA-PARAMS                       151110 
 2866.00            INITIALIZE ZCHAREC-NON-KEY-DATA  OF ZCHA-PARAMS                       151110 
 2867.00                                                                                  151110 
 2868.00            MOVE CHDRMJA-CHDRCOY        TO ZCHA-CHDRCOY                           151110 
 2869.00            MOVE CHDRMJA-CHDRNUM        TO ZCHA-CHDRNUM                           151110 
 2870.00            MOVE ZSCLABCK-EFFDATE       TO ZCHA-CURRFROM                          151110 
 2871.00                                                                                  151110 
 2872.00            MOVE ENDR                   TO ZCHA-FUNCTION                          151110 
 2873.00            PERFORM X1850-CALL-ZCHAIO                                             151110 
 2874.00            IF  ZCHA-CHDRCOY         NOT = CHDRMJA-CHDRCOY                        151110 
 2875.00            OR  ZCHA-CHDRNUM         NOT = CHDRMJA-CHDRNUM                        151110 
 2876.00                MOVE ENDP           TO ZCHA-STATUZ                                151110 
 2877.00            END-IF                                                                151110 
 2878.00                                                                                  151110 
 2879.00            MOVE ZCHA-FORMAT            TO WSAA-SYSR-FORMAT                       151110 
 2880.00            MOVE CHDRMJA-CHDRNUM        TO WSAA-SYSR-CHDRNUM                      151110 
 2881.00            IF  ZCHA-STATUZ      NOT = O-K                                        151110 
 2882.00                MOVE WSAA-SYSR-PARAMS                                             151110 
 2883.00                                    TO SYSR-PARAMS                                151110 
 2884.00                MOVE ZCHA-STATUZ    TO SYSR-STATUZ                                151110 
 2885.00                PERFORM 9000-FATAL-ERROR                                          151110 
 2886.00            END-IF                                                                151110 
 2887.00            MOVE ZCHA-CLNTNUM       TO WSAA-ZCHA-CLNTNUM                          151110 
 2888.00            .                                                                     151110 
 2889.00        X1800-EXIT.                                                               151110 
 2890.00            EXIT.                                                                 151110 
 2891.00       /                                                                          151110 
 2892.00        X1850-CALL-ZCHAIO SECTION.                                                151110 
 2893.00       ***************************                                                151110 
 2894.00        X1850-START.                                                              151110 
 2895.00                                                                                  151110 
 2896.00            MOVE O-K                    TO ZCHA-STATUZ                            151110 
 2897.00            MOVE ZCHAREC                TO ZCHA-FORMAT                            151110 
 2898.00                                                                                  151110 
 2899.00            CALL 'ZCHAIO'            USING ZCHA-PARAMS                            151110 
 2900.00                                                                                  151110 
 2901.00            MOVE ZCHA-FORMAT            TO WSAA-SYSR-FORMAT                       151110 
 2902.00            MOVE CHDRMJA-CHDRNUM        TO WSAA-SYSR-CHDRNUM                      151110 
 2903.00            IF  ZCHA-STATUZ          NOT = O-K                                    151110 
 2904.00            AND ZCHA-STATUZ          NOT = ENDP                                   151110 
 2905.00                MOVE WSAA-SYSR-PARAMS   TO SYSR-PARAMS                            151110 
 2906.00                MOVE ZCHA-STATUZ        TO SYSR-STATUZ                            151110 
 2907.00                PERFORM 9000-FATAL-ERROR                                          151110 
 2908.00            END-IF                                                                151110 
 2909.00            .                                                                     151110 
 2910.00        X1850-EXIT.                                                               151110 
 2911.00            EXIT.                                                                 151110 
 2912.00       /                                                                          151112 
 2913.00        X1900-WRITE-ZCLB SECTION.                                                 151112 
 2914.00       *********************************                                          151112 
 2915.00        X1900-START.                                                              151112 
 2916.00            IF  WSAA-PAID-COMM-CLAWB     = ZEROS                                  151112 
 2917.00                GO TO X1900-EXIT                                                  151112 
 2918.00            END-IF                                                                151112 
 2919.00                                                                                  151112 
 2920.00            INITIALIZE ZCLB-PARAMS                                                151112 
 2921.00            INITIALIZE ZCLBREC-KEY-DATA     OF ZCLB-PARAMS                        151112 
 2922.00            INITIALIZE ZCLBREC-NON-KEY-DATA OF ZCLB-PARAMS                        151112 
 2923.00                                                                                  151112 
 2924.00            MOVE CHDRMJA-CHDRCOY        TO ZCLB-CHDRCOY                           151112 
 2925.00            MOVE CHDRMJA-CHDRNUM        TO ZCLB-CHDRNUM                           151112 
 2926.00            MOVE ZSCLABCK-TRANNO        TO ZCLB-TRANNO                            151112 
 2927.00            MOVE '01'                   TO ZCLB-LIFE                              151112 
 2928.00            MOVE '01'                   TO ZCLB-COVERAGE                          151112 
 2929.00            MOVE '00'                   TO ZCLB-RIDER                             151112 
 2930.00            MOVE ZSCLABCK-EFFDATE       TO ZCLB-PRCDATE                           151112 
 2931.00            MOVE ZSCLABCK-EFFDATE       TO ZCLB-EFFDATE                           151112 
 2932.00            MOVE ZSCLABCK-BATCTRCDE     TO ZCLB-BATCTRCDE                         151112 
 2933.00                                                                                  151214 
 2934.00            MOVE WSAA-PAID-PREM         TO ZCLB-ZINTPREM                          151214 
 2935.00            MOVE WSAA-PAID-COMM         TO ZCLB-ZINTCOMM01                        151214 
 2936.00            MOVE WSAA-PAID-OVRCOM       TO ZCLB-ZINTCOMM02                        151214 
 2937.00                                                                                  151214 
 2938.00            COMPUTE ZCLB-ZPREMAMT        = WSAA-PAID-PREM-CLAWB                   151112 
 2939.00                                         * WSCC-NUM--1                            151112 
 2940.00            END-COMPUTE                                                           151112 
 2941.00            COMPUTE ZCLB-ZCOMMAMT01      = WSAA-PAID-COMM-CLAWB                   151112 
 2942.00                                         * WSCC-NUM--1                            151112 
 2943.00            END-COMPUTE                                                           151112 
 2944.00            COMPUTE ZCLB-ZCOMMAMT02      = WSAA-PAID-OVRCOM-CLAWB                 151112 
 2945.00                                         * WSCC-NUM--1                            151112 
 2946.00            END-COMPUTE                                                           151112 
 2947.00            MOVE WSAA-AGNTNUM                                                     151112 
 2948.00                                        TO ZCLB-AGNTNUM                           151112 
 2949.00            PERFORM XA25-CALL-ALOCNO                                              151112 
 2950.00            MOVE WSAA-JPREMREG          TO ZCLB-JPREMREG                          151112 
 2951.00            MOVE WSAA-ZCLB-RECODE       TO ZCLB-RECODE                   <ATHA67> 160408 
 2952.00            MOVE WSAA-PARTS-PERC        TO ZCLB-PERCREQD                 <ATHA67> 160406 
 2953.00            COMPUTE ZCLB-PRCNT ROUNDED   = WSAA-T8Z82                    <ATHA67> 160408 
 2954.00                                         * 100                           <ATHA67> 160408 
 2955.00                                                                                  151112 
 2956.00            MOVE WRITR                  TO ZCLB-FUNCTION                          151112 
 2957.00            PERFORM X1950-ZCLB-IO                                                 151112 
 2958.00            .                                                                     151112 
 2959.00        X1900-EXIT.                                                               151112 
 2960.00            EXIT.                                                                 151112 
 2961.00       /                                                                          151112 
 2962.00        X1950-ZCLB-IO SECTION.                                                    151112 
 2963.00       **************************                                                 151112 
 2964.00        X1950-START.                                                              151112 
 2965.00                                                                                  151112 
 2966.00            MOVE O-K                 TO ZCLB-STATUZ                               151112 
 2967.00            MOVE ZCLBREC             TO ZCLB-FORMAT                               151112 
 2968.00                                                                                  151112 
 2969.00            CALL 'ZCLBIO'         USING ZCLB-PARAMS                               151112 
 2970.00                                                                                  151112 
 2971.00            IF  ZCLB-STATUZ       NOT = O-K                                       151112 
 2972.00                MOVE ZCLB-STATUZ     TO SYSR-STATUZ                               151112 
 2973.00                MOVE ZCLB-PARAMS     TO SYSR-PARAMS                               151112 
 2974.00                PERFORM 9000-FATAL-ERROR                                          151112 
 2975.00            END-IF                                                                151112 
 2976.00            .                                                                     151112 
 2977.00        X1950-EXIT.                                                               151112 
 2978.00            EXIT.                                                        <ATHA39> 151112 
 2979.00       /                                                                          151116 
 2980.00        X1900A-WRITE-ZCLB-TOPUP SECTION.                                          151116 
 2981.00       *********************************                                          151116 
 2982.00        X1900A-START.                                                             151122 
 2983.00                                                                                  151116 
 2984.00            INITIALIZE ZCLB-PARAMS                                                151116 
 2985.00            INITIALIZE ZCLBREC-KEY-DATA     OF ZCLB-PARAMS                        151116 
 2986.00            INITIALIZE ZCLBREC-NON-KEY-DATA OF ZCLB-PARAMS                        151116 
 2987.00                                                                                  151116 
 2988.00            MOVE CHDRMJA-CHDRCOY        TO ZCLB-CHDRCOY                           151116 
 2989.00            MOVE CHDRMJA-CHDRNUM        TO ZCLB-CHDRNUM                           151116 
 2990.00            MOVE ZSCLABCK-TRANNO        TO ZCLB-TRANNO                            151116 
 2991.00       ***  MOVE '01'                   TO ZCLB-LIFE                     <ATHB45> 170313 
 2992.00       ***  MOVE '02'                   TO ZCLB-COVERAGE                 <ATHB45> 170313 
 2993.00       ***  MOVE '00'                   TO ZCLB-RIDER                    <ATHB45> 170313 
 2994.00            MOVE WSAA-TU-LIFE           TO ZCLB-LIFE                     <ATHB45> 170313 
 2995.00            MOVE WSAA-TU-COVERAGE       TO ZCLB-COVERAGE                 <ATHB45> 170313 
 2996.00            MOVE WSAA-TU-RIDER          TO ZCLB-RIDER                    <ATHB45> 170313 
 2997.00            MOVE ZSCLABCK-EFFDATE       TO ZCLB-PRCDATE                           151116 
 2998.00            MOVE ZSCLABCK-EFFDATE       TO ZCLB-EFFDATE                           151116 
 2999.00            MOVE ZSCLABCK-BATCTRCDE     TO ZCLB-BATCTRCDE                         151116 
 3000.00                                                                                  151214 
 3001.00            MOVE WSAA-PAID-PREM         TO ZCLB-ZINTPREM                          151214 
 3002.00            MOVE WSAA-PAID-COMM         TO ZCLB-ZINTCOMM01                        151214 
 3003.00            MOVE WSAA-PAID-OVRCOM       TO ZCLB-ZINTCOMM02                        151214 
 3004.00                                                                                  151214 
 3005.00            COMPUTE ZCLB-ZPREMAMT        = WSAA-TOT-CLAWB-NET                     151116 
 3006.00                                         * WSCC-NUM--1                            151116 
 3007.00            END-COMPUTE                                                           151116 
 3008.00            COMPUTE ZCLB-ZCOMMAMT01      = WSAA-TOT-CLAWB-TOPUP                   151116 
 3009.00                                         * WSCC-NUM--1                            151116 
 3010.00            END-COMPUTE                                                           151116 
 3011.00            COMPUTE ZCLB-ZCOMMAMT02      = WSAA-TOT-CLAWB-OVRAMT                  151116 
 3012.00                                         * WSCC-NUM--1                            151116 
 3013.00            END-COMPUTE                                                           151116 
 3014.00            MOVE WSAA-AGNTNUM                                                     151116 
 3015.00                                        TO ZCLB-AGNTNUM                           151116 
 3016.00            PERFORM XA25-CALL-ALOCNO                                              151116 
 3017.00            MOVE WSAA-JPREMREG          TO ZCLB-JPREMREG                          151116 
 3018.00                                                                                  151116 
 3019.00            MOVE WRITR                  TO ZCLB-FUNCTION                          151116 
 3020.00            PERFORM X1950-ZCLB-IO                                                 151116 
 3021.00            .                                                                     151116 
 3022.00        X1900A-EXIT.                                                              151116 
 3023.00            EXIT.                                                                 151116 
 3024.00       /                                                                          151214 
 3025.00        X1900B-WRITE-ZCLB-TOPUP SECTION.                                          151214 
 3026.00       *********************************                                          151214 
 3027.00        X1900B-START.                                                             151214 
 3028.00                                                                                  151214 
 3029.00            INITIALIZE ZCLB-PARAMS                                                151214 
 3030.00            INITIALIZE ZCLBREC-KEY-DATA     OF ZCLB-PARAMS                        151214 
 3031.00            INITIALIZE ZCLBREC-NON-KEY-DATA OF ZCLB-PARAMS                        151214 
 3032.00                                                                                  151214 
 3033.00            MOVE CHDRMJA-CHDRCOY        TO ZCLB-CHDRCOY                           151214 
 3034.00            MOVE CHDRMJA-CHDRNUM        TO ZCLB-CHDRNUM                           151214 
 3035.00            MOVE ZSCLABCK-TRANNO        TO ZCLB-TRANNO                            151214 
 3036.00       ***  MOVE '01'                   TO ZCLB-LIFE                     <ATHB45> 170313 
 3037.00       ***  MOVE '02'                   TO ZCLB-COVERAGE                 <ATHB45> 170313 
 3038.00       ***  MOVE '00'                   TO ZCLB-RIDER                    <ATHB45> 170313 
 3039.00            MOVE WSAA-TU-LIFE           TO ZCLB-LIFE                     <ATHB45> 170313 
 3040.00            MOVE WSAA-TU-COVERAGE       TO ZCLB-COVERAGE                 <ATHB45> 170313 
 3041.00            MOVE WSAA-TU-RIDER          TO ZCLB-RIDER                    <ATHB45> 170313 
 3042.00            MOVE ZSCLABCK-EFFDATE       TO ZCLB-PRCDATE                           151214 
 3043.00            MOVE WSAA-FROM-DATE         TO ZCLB-EFFDATE                           151214 
 3044.00            MOVE ZSCLABCK-BATCTRCDE     TO ZCLB-BATCTRCDE                         151214 
 3045.00            MOVE WSAA-PAID-PREM         TO ZCLB-ZINTPREM                          151214 
 3046.00            MOVE WSAA-PAID-COMM         TO ZCLB-ZINTCOMM01                        151214 
 3047.00            MOVE WSAA-PAID-OVRCOM       TO ZCLB-ZINTCOMM02                        151214 
 3048.00            COMPUTE ZCLB-ZPREMAMT        = WSAA-CLAWBACK-NET                      151214 
 3049.00                                         * WSCC-NUM--1                            151214 
 3050.00            END-COMPUTE                                                           151214 
 3051.00            COMPUTE ZCLB-ZCOMMAMT01      = WSAA-CLAWBACK-TOPUP                    151214 
 3052.00                                         * WSCC-NUM--1                            151214 
 3053.00            END-COMPUTE                                                           151214 
 3054.00            COMPUTE ZCLB-ZCOMMAMT02      = WSAA-CLAWBACK-OVRAMT                   151214 
 3055.00                                         * WSCC-NUM--1                            151214 
 3056.00            END-COMPUTE                                                           151214 
 3057.00            MOVE WSAA-AGNTNUM                                                     151214 
 3058.00                                        TO ZCLB-AGNTNUM                           151214 
 3059.00            PERFORM XA25-CALL-ALOCNO                                              151214 
 3060.00            MOVE WSAA-JPREMREG          TO ZCLB-JPREMREG                          151214 
 3061.00            MOVE WSAA-ZCLB-RECODE       TO ZCLB-RECODE                   <ATHA67> 160406 
 3062.00            MOVE WSAA-PARTS-PERC        TO ZCLB-PERCREQD                 <ATHA67> 160406 
 3063.00            COMPUTE ZCLB-PRCNT ROUNDED   = WSAA-T8Z82                    <ATHA67> 160408 
 3064.00                                         * 100                           <ATHA67> 160408 
 3065.00                                                                                  151214 
 3066.00            MOVE WRITR                  TO ZCLB-FUNCTION                          151214 
 3067.00            PERFORM X1950-ZCLB-IO                                                 151214 
 3068.00            .                                                                     151214 
 3069.00        X1900B-EXIT.                                                              151214 
 3070.00            EXIT.                                                                 151214 
 3071.00       /                                                                          151113 
 3072.00        X2000-DUE-ACCOUNTINGS SECTION.                                            151113 
 3073.00       *******************************                                            151113 
 3074.00        X2000-START.                                                              151113 
 3075.00                                                                                  151113 
 3076.00            PERFORM X2050-READ-AGLF                                               151113 
 3077.00                                                                                  151113 
 3078.00            IF  WSAA-PAID-OVRCOM-CLAWB                                            151113 
 3079.00                                         > ZEROS                                  151113 
 3080.00                MOVE ZSCLABCK-CHDRNUM       TO WSAA-RLDG-CHDRNUM                  151113 
 3081.00                MOVE '01'                   TO WSAA-RLDG-LIFE                     151113 
 3082.00                MOVE '01'                   TO WSAA-RLDG-COVERAGE                 151113 
 3083.00                MOVE '00'                   TO WSAA-RLDG-RIDER                    151113 
 3084.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151113 
 3085.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151113 
 3086.00       **       MOVE WSAA-PAID-OVRCOM-CLAWB                                       151113 
 3087.00       **                               TO LIFA-ORIGAMT                           151113 
 3088.00                COMPUTE LIFA-ORIGAMT     = WSAA-PAID-OVRCOM-CLAWB                 151113 
 3089.00                                         * WSCC-NUM--1                            151113 
 3090.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151113 
 3091.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151113 
 3092.00                MOVE 11                 TO IX-SA                                  151113 
 3093.00                PERFORM X1450-POST-COMM                                           151113 
 3094.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151113 
 3095.00                MOVE 12                 TO IX-SA                                  151113 
 3096.00                PERFORM X1450-POST-COMM                                           151113 
 3097.00            END-IF                                                                151113 
 3098.00            IF  WSAA-PAID-COMM-CLAWB                                              151113 
 3099.00                                         > ZEROS                                  151113 
 3100.00       **       MOVE WSAA-PAID-COMM-CLAWB                                         151113 
 3101.00       **                               TO LIFA-ORIGAMT                           151113 
 3102.00                COMPUTE LIFA-ORIGAMT     = WSAA-PAID-COMM-CLAWB                   151113 
 3103.00                                         * WSCC-NUM--1                            151113 
 3104.00                MOVE SPACES             TO LIFA-RLDGACCT                          151113 
 3105.00                MOVE SPACES             TO LIFA-RLDGACCT                          151113 
 3106.00                MOVE WSAA-AGNTNUM       TO LIFA-RLDGACCT                          151113 
 3107.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151113 
 3108.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151113 
 3109.00                MOVE 8                  TO IX-SA                                  151113 
 3110.00                PERFORM X1450-POST-COMM                                           151113 
 3111.00                                                                                  151113 
 3112.00                MOVE SPACES             TO LIFA-RLDGACCT                          151113 
 3113.00                MOVE ZSCLABCK-CHDRNUM       TO WSAA-RLDG-CHDRNUM                  151113 
 3114.00                MOVE '01'                   TO WSAA-RLDG-LIFE                     151113 
 3115.00                MOVE '01'                   TO WSAA-RLDG-COVERAGE                 151113 
 3116.00                MOVE '00'                   TO WSAA-RLDG-RIDER                    151113 
 3117.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151113 
 3118.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151113 
 3119.00                MOVE WSAA-AGNTNUM       TO WSAA-TRANCHDR                          151113 
 3120.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151113 
 3121.00                MOVE 7                  TO IX-SA                                  151113 
 3122.00                PERFORM X1450-POST-COMM                                           151113 
 3123.00            END-IF                                                                151113 
 3124.00                                                                                  151113 
 3125.00            IF  WSAA-PAID-PREM-CLAWB                                              151113 
 3126.00                                         > ZEROS                                  151113 
 3127.00            AND WSAA-PAID-COMM-CLAWB                                              151113 
 3128.00                                         > ZEROS                                  151113 
 3129.00       **       MOVE WSAA-PAID-PREM-CLAWB                                         151113 
 3130.00       **                               TO LIFA-ORIGAMT                           151113 
 3131.00                COMPUTE LIFA-ORIGAMT     = WSAA-PAID-PREM-CLAWB                   151113 
 3132.00                                         * WSCC-NUM--1                            151113 
 3133.00                MOVE ZSCLABCK-CHDRNUM       TO WSAA-RLDG-CHDRNUM                  151113 
 3134.00                MOVE '01'                   TO WSAA-RLDG-LIFE                     151113 
 3135.00                MOVE '01'                   TO WSAA-RLDG-COVERAGE                 151113 
 3136.00                MOVE '00'                   TO WSAA-RLDG-RIDER                    151113 
 3137.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151113 
 3138.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151113 
 3139.00                MOVE WSAA-AGNTNUM       TO WSAA-TRANCHDR                          151113 
 3140.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151113 
 3141.00                MOVE 15                 TO IX-SA                                  151113 
 3142.00                PERFORM X1450-POST-COMM                                           151113 
 3143.00                MOVE 16                 TO IX-SA                                  151113 
 3144.00                PERFORM X1450-POST-COMM                                           151113 
 3145.00            END-IF                                                                151113 
 3146.00            .                                                                     151113 
 3147.00        X2000-EXIT.                                                               151113 
 3148.00            EXIT.                                                                 151113 
 3149.00       /                                                                          151113 
 3150.00        X2050-READ-AGLF SECTION.                                                  151113 
 3151.00       *******************************                                            151113 
 3152.00        X2050-START.                                                              151113 
 3153.00                                                                                  151113 
 3154.00            INITIALIZE AGLFREC-KEY-DATA OF AGLF-PARAMS                            151113 
 3155.00            INITIALIZE AGLFREC-NON-KEY-DATA                                       151113 
 3156.00                                        OF AGLF-PARAMS                            151113 
 3157.00            MOVE ZSCLABCK-CHDRCOY       TO AGLF-AGNTCOY                           151113 
 3158.00            MOVE WSAA-AGNTNUM           TO AGLF-AGNTNUM                           151113 
 3159.00            MOVE READR                  TO AGLF-FUNCTION                          151113 
 3160.00            CALL 'AGLFIO'            USING AGLF-PARAMS                            151113 
 3161.00                                                                                  151113 
 3162.00            IF  AGLF-STATUZ          NOT = O-K                                    151113 
 3163.00            AND AGLF-STATUZ          NOT = MRNF                                   151113 
 3164.00                MOVE AGLF-PARAMS         TO SYSR-PARAMS                           151113 
 3165.00                MOVE AGLF-STATUZ         TO SYSR-STATUZ                           151113 
 3166.00                PERFORM 9000-FATAL-ERROR                                          151113 
 3167.00            END-IF                                                                151113 
 3168.00                                                                                  151113 
 3169.00            MOVE AGLF-JAGNTLVL          TO WSAA-TRANAGNT                          151113 
 3170.00            MOVE AGLF-JAGNTLVL          TO WSAA-TRANAGNT-TOP                      151214 
 3171.00            .                                                                     151113 
 3172.00        X2050-EXIT.                                                               151113 
 3173.00            EXIT.                                                                 151113 
 3174.00       /                                                                          151113 
 3175.00        X2100-COLL-ACCOUNTINGS SECTION.                                           151113 
 3176.00       *******************************                                            151113 
 3177.00        X2100-START.                                                              151113 
 3178.00                                                                                  151113 
 3179.00            IF  WSAA-PAID-OVRCOM-CLAWB                                            151113 
 3180.00                                         > ZEROS                                  151113 
 3181.00                MOVE ZSCLABCK-CHDRNUM       TO WSAA-RLDG-CHDRNUM                  151113 
 3182.00                MOVE '01'                   TO WSAA-RLDG-LIFE                     151113 
 3183.00                MOVE '01'                   TO WSAA-RLDG-COVERAGE                 151113 
 3184.00                MOVE '00'                   TO WSAA-RLDG-RIDER                    151113 
 3185.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151113 
 3186.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151113 
 3187.00       **                                                                         151113 
 3188.00                COMPUTE LIFA-ORIGAMT     = WSAA-PAID-OVRCOM-CLAWB                 151113 
 3189.00                                         * WSCC-NUM--1                            151113 
 3190.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151113 
 3191.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151113 
 3192.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151113 
 3193.00                MOVE 1                  TO IX-SA                                  151113 
 3194.00                PERFORM X1450-POST-COMM                                           151113 
 3195.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151113 
 3196.00                MOVE 2                  TO IX-SA                                  151113 
 3197.00                PERFORM X1450-POST-COMM                                           151113 
 3198.00            END-IF                                                                151113 
 3199.00                                                                                  151113 
 3200.00            IF  WSAA-PAID-COMM-CLAWB                                              151113 
 3201.00                                         > ZEROS                                  151113 
 3202.00                COMPUTE LIFA-ORIGAMT     = WSAA-PAID-COMM-CLAWB                   151113 
 3203.00                                         * WSCC-NUM--1                            151113 
 3204.00                                                                                  151113 
 3205.00                MOVE SPACES             TO LIFA-RLDGACCT                          151113 
 3206.00                MOVE WSAA-AGNTNUM       TO LIFA-RLDGACCT                          151113 
 3207.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151113 
 3208.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151113 
 3209.00                MOVE 3                  TO IX-SA                                  151113 
 3210.00                PERFORM X1450-POST-COMM                                           151113 
 3211.00                MOVE 'Y'                TO WSAA-EXT-IGNORE                        151113 
 3212.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151114 
 3213.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151114 
 3214.00                MOVE 4                  TO IX-SA                                  151113 
 3215.00                PERFORM X1450-POST-COMM                                           151113 
 3216.00            END-IF                                                                151113 
 3217.00            MOVE ' '                TO WSAA-EXT-IGNORE                            151113 
 3218.00            IF  WSAA-PAID-PREM-CLAWB                                              151113 
 3219.00                                         > ZEROS                                  151113 
 3220.00            AND WSAA-PAID-COMM-CLAWB                                              151113 
 3221.00                                         > ZEROS                                  151113 
 3222.00       **       MOVE WSAA-PAID-PREM-CLAWB                                         151113 
 3223.00       **                               TO LIFA-ORIGAMT                           151113 
 3224.00                COMPUTE LIFA-ORIGAMT     = WSAA-PAID-PREM-CLAWB                   151113 
 3225.00                                         * WSCC-NUM--1                            151113 
 3226.00                MOVE ZSCLABCK-CHDRNUM       TO WSAA-RLDG-CHDRNUM                  151113 
 3227.00                MOVE '01'                   TO WSAA-RLDG-LIFE                     151113 
 3228.00                MOVE '01'                   TO WSAA-RLDG-COVERAGE                 151113 
 3229.00                MOVE '00'                   TO WSAA-RLDG-RIDER                    151113 
 3230.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151113 
 3231.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151113 
 3232.00                MOVE WSAA-AGNTNUM       TO WSAA-TRANCHDR                          151113 
 3233.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151113 
 3234.00                MOVE 5                  TO IX-SA                                  151113 
 3235.00                PERFORM X1450-POST-COMM                                           151113 
 3236.00                MOVE 6                  TO IX-SA                                  151113 
 3237.00                PERFORM X1450-POST-COMM                                           151113 
 3238.00            END-IF                                                                151113 
 3239.00            .                                                                     151113 
 3240.00        X2100-EXIT.                                                               151113 
 3241.00            EXIT.                                                                 151113 
 3242.00       /                                                                          151122 
 3243.00        X2110-SP-ACCOUNTINGS SECTION.                                             151122 
 3244.00       *******************************                                            151122 
 3245.00        X2110-START.                                                              151122 
 3246.00                                                                                  151122 
 3247.00            PERFORM X2050-READ-AGLF                                               151123 
 3248.00            IF  WSAA-PAID-OVRCOM-CLAWB                                            151122 
 3249.00                                         > ZEROS                                  151122 
 3250.00                MOVE ZSCLABCK-CHDRNUM       TO WSAA-RLDG-CHDRNUM                  151122 
 3251.00                MOVE '01'                   TO WSAA-RLDG-LIFE                     151122 
 3252.00                MOVE '01'                   TO WSAA-RLDG-COVERAGE                 151122 
 3253.00                MOVE '00'                   TO WSAA-RLDG-RIDER                    151122 
 3254.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151122 
 3255.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151122 
 3256.00       **                                                                         151122 
 3257.00                COMPUTE LIFA-ORIGAMT     = WSAA-PAID-OVRCOM-CLAWB                 151122 
 3258.00                                         * WSCC-NUM--1                            151122 
 3259.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151122 
 3260.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151122 
 3261.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151122 
 3262.00                MOVE 1                  TO IX-SA                                  151122 
 3263.00                PERFORM X1450-POST-COMM                                           151122 
 3264.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151122 
 3265.00                MOVE 11                 TO IX-SA                         <ATHA67> 160407 
 3266.00                PERFORM X1450-POST-COMM                                           151122 
 3267.00            END-IF                                                                151122 
 3268.00                                                                                  151122 
 3269.00            IF  WSAA-PAID-COMM-CLAWB                                              151122 
 3270.00                                         > ZEROS                                  151122 
 3271.00                COMPUTE LIFA-ORIGAMT     = WSAA-PAID-COMM-CLAWB                   151122 
 3272.00                                         * WSCC-NUM--1                            151122 
 3273.00                MOVE SPACES             TO LIFA-RLDGACCT                          151122 
 3274.00                MOVE ZSCLABCK-CHDRNUM       TO WSAA-RLDG-CHDRNUM                  151122 
 3275.00                MOVE '01'                   TO WSAA-RLDG-LIFE                     151122 
 3276.00                MOVE '01'                   TO WSAA-RLDG-COVERAGE                 151122 
 3277.00                MOVE '00'                   TO WSAA-RLDG-RIDER                    151122 
 3278.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151122 
 3279.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151122 
 3280.00       *        MOVE WSAA-AGNTNUM       TO WSAA-TRANCHDR                          151123 
 3281.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151123 
 3282.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151122 
 3283.00                MOVE 17                 TO IX-SA                                  151122 
 3284.00                PERFORM X1450-POST-COMM                                           151122 
 3285.00                MOVE SPACES             TO LIFA-RLDGACCT                          151122 
 3286.00                MOVE WSAA-AGNTNUM       TO LIFA-RLDGACCT                          151122 
 3287.00                MOVE ZSCLABCK-CHDRNUM   TO WSAA-TRANCHDR                          151122 
 3288.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151122 
 3289.00                MOVE 18                 TO IX-SA                                  151122 
 3290.00                PERFORM X1450-POST-COMM                                           151122 
 3291.00                                                                                  151122 
 3292.00            END-IF                                                                151122 
 3293.00                                                                                  151122 
 3294.00            MOVE ' '                TO WSAA-EXT-IGNORE                            151122 
 3295.00            IF  WSAA-PAID-PREM-CLAWB                                              151122 
 3296.00                                         > ZEROS                                  151122 
 3297.00            AND WSAA-PAID-COMM-CLAWB                                              151122 
 3298.00                                         > ZEROS                                  151122 
 3299.00       **       MOVE WSAA-PAID-PREM-CLAWB                                         151122 
 3300.00       **                               TO LIFA-ORIGAMT                           151122 
 3301.00                COMPUTE LIFA-ORIGAMT     = WSAA-PAID-PREM-CLAWB                   151122 
 3302.00                                         * WSCC-NUM--1                            151122 
 3303.00                MOVE ZSCLABCK-CHDRNUM       TO WSAA-RLDG-CHDRNUM                  151122 
 3304.00                MOVE '01'                   TO WSAA-RLDG-LIFE                     151122 
 3305.00                MOVE '01'                   TO WSAA-RLDG-COVERAGE                 151122 
 3306.00                MOVE '00'                   TO WSAA-RLDG-RIDER                    151122 
 3307.00                MOVE 0000                   TO WSAA-RLDG-PLAN-SUFFIX              151122 
 3308.00                MOVE WSAA-RLDGACCT          TO LIFA-RLDGACCT                      151122 
 3309.00                MOVE WSAA-AGNTNUM       TO WSAA-TRANCHDR                          151122 
 3310.00                MOVE WSAA-TRANREF           TO LIFA-TRANREF                       151122 
 3311.00                MOVE 13                 TO IX-SA                                  151123 
 3312.00                PERFORM X1450-POST-COMM                                           151122 
 3313.00                MOVE 14                 TO IX-SA                                  151123 
 3314.00                PERFORM X1450-POST-COMM                                           151122 
 3315.00            END-IF                                                                151122 
 3316.00            .                                                                     151122 
 3317.00        X2110-EXIT.                                                               151122 
 3318.00            EXIT.                                                                 151122 
 3319.00       /                                                                          151114 
 3320.00        X2200-READ-PTRNREV SECTION.                                               151114 
 3321.00       *******************************                                            151114 
 3322.00        X2200-START.                                                              151114 
 3323.00                                                                                  151114 
 3324.00            SET NOT-VALID-RECORD    TO TRUE                                       151114 
 3325.00            INITIALIZE PTRNREVREC-KEY-DATA OF PTRNREV-PARAMS                      151114 
 3326.00            INITIALIZE PTRNREVREC-NON-KEY-DATA                                    151114 
 3327.00                                        OF PTRNREV-PARAMS                         151114 
 3328.00            MOVE ACMVBK3-RLDGCOY       TO PTRNREV-CHDRCOY                         151114 
 3329.00            MOVE ACMVBK3-RDOCNUM        TO PTRNREV-CHDRNUM                        151114 
 3330.00            MOVE ACMVBK3-TRANNO         TO PTRNREV-TRANNO                         151114 
 3331.00            MOVE READR                  TO PTRNREV-FUNCTION                       151114 
 3332.00            CALL 'PTRNREVIO'            USING PTRNREV-PARAMS                      151114 
 3333.00                                                                                  151114 
 3334.00            IF  PTRNREV-STATUZ       NOT = O-K                                    151114 
 3335.00            AND PTRNREV-STATUZ          NOT = MRNF                                151114 
 3336.00                MOVE PTRNREV-PARAMS         TO SYSR-PARAMS                        151114 
 3337.00                MOVE PTRNREV-STATUZ         TO SYSR-STATUZ                        151114 
 3338.00                PERFORM 9000-FATAL-ERROR                                          151114 
 3339.00            END-IF                                                                151114 
 3340.00                                                                                  151114 
 3341.00            IF  PTRNREV-STATUZ           = O-K                                    151114 
 3342.00            AND PTRNREV-BATCTRCDE        = WSAA-BATCTRCDE                         151114 
 3343.00                SET VALID-RECORD        TO TRUE                                   151114 
 3344.00            END-IF                                                                151114 
 3345.00            .                                                                     151114 
 3346.00        X2200-EXIT.                                                               151114 
 3347.00            EXIT.                                                                 151114 
 3348.00       /                                                                 <ATHA67> 160404 
 3349.00        X3000-READ-ZCLBCOV SECTION.                                      <ATHA67> 160404 
 3350.00       *******************************                                   <ATHA67> 160404 
 3351.00        X3000-START.                                                     <ATHA67> 160404 
 3352.00                                                                         <ATHA67> 160404 
 3353.00            MOVE ZEROS                  TO WSAA-PRV-CLAW-PREM            <ATHA67> 160404 
 3354.00            MOVE ZEROS                  TO WSAA-PRV-CLAW-COMM            <ATHA67> 160404 
 3355.00            MOVE ZEROS                  TO WSAA-PRV-CLAW-OVRC            <ATHA67> 160404 
 3356.00            MOVE ZEROS                  TO WSAA-CLAW-PREM-REMN           <ATHA67> 160404 
 3357.00            MOVE ZEROS                  TO WSAA-CLAW-COMM-REMN           <ATHA67> 160404 
 3358.00            MOVE ZEROS                  TO WSAA-CLAW-OVRC-REMN           <ATHA67> 160404 
 3359.00            INITIALIZE ZCLBCOVREC-KEY-DATA OF ZCLBCOV-PARAMS             <ATHA67> 160404 
 3360.00            INITIALIZE ZCLBCOVREC-NON-KEY-DATA                           <ATHA67> 160404 
 3361.00                                        OF ZCLBCOV-PARAMS                <ATHA67> 160404 
 3362.00            MOVE CHDRMJA-CHDRCOY       TO ZCLBCOV-CHDRCOY                <ATHA67> 160404 
 3363.00            MOVE CHDRMJA-CHDRNUM        TO ZCLBCOV-CHDRNUM               <ATHA67> 160404 
 3364.00            MOVE WSAA-ZCLB-LIFE         TO ZCLBCOV-LIFE                  <ATHA67> 160404 
 3365.00            MOVE WSAA-ZCLB-COVERAGE     TO ZCLBCOV-COVERAGE              <ATHA67> 160404 
 3366.00            MOVE WSAA-ZCLB-RIDER        TO ZCLBCOV-RIDER                 <ATHA67> 160404 
 3367.00            MOVE BEGN                   TO ZCLBCOV-FUNCTION              <ATHA67> 160404 
 3368.00            PERFORM X3050-ZCLBCOV-IO                                     <ATHA67> 160404 
 3369.00            PERFORM                                                      <ATHA67> 160404 
 3370.00               UNTIL ZCLBCOV-STATUZ      = ENDP                          <ATHA67> 160404 
 3371.00                                                                         <ATHA67> 160404 
 3372.00                     IF  ZCLBCOV-RECODE         = WSAA-ZCLB-RECODE       <ATHA67> 160406 
 3373.00                     AND WSAA-AGNTNUM           = ZCLBCOV-AGNTNUM        <ATHA67> 160513 
 3374.00                     COMPUTE WSAA-PRV-CLAW-PREM = ZCLBCOV-ZPREMAMT       <ATHA67> 160404 
 3375.00                                                + WSAA-PRV-CLAW-PREM     <ATHA67> 160404 
 3376.00                     COMPUTE WSAA-PRV-CLAW-COMM = ZCLBCOV-ZCOMMAMT01     <ATHA67> 160404 
 3377.00                                                + WSAA-PRV-CLAW-COMM     <ATHA67> 160404 
 3378.00                     COMPUTE WSAA-PRV-CLAW-OVRC = ZCLBCOV-ZCOMMAMT02     <ATHA67> 160404 
 3379.00                                                + WSAA-PRV-CLAW-OVRC     <ATHA67> 160404 
 3380.00                     END-IF                                              <ATHA67> 160406 
 3381.00                                                                         <ATHA67> 160404 
 3382.00               MOVE NEXTR               TO ZCLBCOV-FUNCTION              <ATHA67> 160404 
 3383.00               PERFORM X3050-ZCLBCOV-IO                                  <ATHA67> 160404 
 3384.00            END-PERFORM                                                  <ATHA67> 160404 
 3385.00                                                                         <ATHA67> 160404 
 3386.00            .                                                            <ATHA67> 160404 
 3387.00        X3000-EXIT.                                                      <ATHA67> 160404 
 3388.00            EXIT.                                                        <ATHA67> 160404 
 3389.00       /                                                                 <ATHA67> 160404 
 3390.00        X3050-ZCLBCOV-IO SECTION.                                        <ATHA67> 160404 
 3391.00       *************************                                         <ATHA67> 160404 
 3392.00        X3050-START.                                                     <ATHA67> 160404 
 3393.00                                                                         <ATHA67> 160404 
 3394.00            MOVE ZCLBCOVREC             TO ZCLBCOV-FORMAT                <ATHA67> 160404 
 3395.00            CALL 'ZCLBCOVIO'         USING ZCLBCOV-PARAMS.               <ATHA67> 160404 
 3396.00                                                                         <ATHA67> 160404 
 3397.00            IF  ZCLBCOV-STATUZ NOT = O-K                                 <ATHA67> 160404 
 3398.00            AND ZCLBCOV-STATUZ NOT = ENDP                                <ATHA67> 160404 
 3399.00                MOVE ZCLBCOV-PARAMS   TO SYSR-PARAMS                     <ATHA67> 160404 
 3400.00                PERFORM 9000-FATAL-ERROR                                 <ATHA67> 160404 
 3401.00            END-IF                                                       <ATHA67> 160404 
 3402.00            IF  ZCLBCOV-CHDRCOY   NOT = CHDRMJA-CHDRCOY                  <ATHA67> 160404 
 3403.00            OR  ZCLBCOV-CHDRNUM   NOT = CHDRMJA-CHDRNUM                  <ATHA67> 160404 
 3404.00            OR  ZCLBCOV-LIFE      NOT = WSAA-ZCLB-LIFE                   <ATHA67> 160404 
 3405.00            OR  ZCLBCOV-COVERAGE  NOT = WSAA-ZCLB-COVERAGE               <ATHA67> 160404 
 3406.00            OR  ZCLBCOV-RIDER     NOT = WSAA-ZCLB-RIDER                  <ATHA67> 160404 
 3407.00                MOVE ENDP         TO ZCLBCOV-STATUZ                      <ATHA67> 160404 
 3408.00            END-IF                                                       <ATHA67> 160404 
 3409.00            .                                                            <ATHA67> 160404 
 3410.00        X3050-EXIT.                                                      <ATHA67> 160404 
 3411.00            EXIT.                                                        <ATHA67> 160404 
 3412.00       /                                                                 <ATHA67> 160404 
 3413.00        X3100-FIND-CLAWB-REMN-REGP SECTION.                              <ATHA67> 160404 
 3414.00       ************************************                              <ATHA67> 160404 
 3415.00        X3100-START.                                                     <ATHA67> 160404 
 3416.00                                                                         <ATHA67> 160404 
 3417.00            COMPUTE WSAA-PRV-CLAW-PREM   = WSAA-PRV-CLAW-PREM            <ATHA67> 160404 
 3418.00                                         * -1                            <ATHA67> 160404 
 3419.00            COMPUTE WSAA-PRV-CLAW-COMM   = WSAA-PRV-CLAW-COMM            <ATHA67> 160404 
 3420.00                                         * -1                            <ATHA67> 160404 
 3421.00            COMPUTE WSAA-PRV-CLAW-OVRC   = WSAA-PRV-CLAW-OVRC            <ATHA67> 160404 
 3422.00                                         * -1                            <ATHA67> 160404 
 3423.00            COMPUTE WSAA-CLAW-PREM-REMN  = WSAA-PAID-PREM                <ATHA67> 160404 
 3424.00                                         - WSAA-PRV-CLAW-PREM            <ATHA67> 160404 
 3425.00            COMPUTE WSAA-CLAW-COMM-REMN  = WSAA-PAID-COMM                <ATHA67> 160404 
 3426.00                                         - WSAA-PRV-CLAW-COMM            <ATHA67> 160404 
 3427.00            COMPUTE WSAA-CLAW-OVRC-REMN  = WSAA-PAID-OVRCOM              <ATHA67> 160404 
 3428.00                                         - WSAA-PRV-CLAW-OVRC            <ATHA67> 160404 
 3429.00                                                                         <ATHA67> 160404 
 3430.00            IF  WSAA-CLAW-COMM-REMN     <  WSAA-PAID-COMM-CLAWB          <ATHA67> 160404 
 3431.00                IF  WSAA-CLAW-COMM-REMN  <= ZEROS                        <ATHA67> 160404 
 3432.00                    MOVE ZEROS          TO WSAA-PAID-COMM-CLAWB          <ATHA67> 160404 
 3433.00                    MOVE ZEROS          TO WSAA-PAID-PREM-CLAWB          <ATHA67> 160404 
 3434.00                    MOVE ZEROS          TO WSAA-PAID-OVRCOM-CLAWB        <ATHA67> 160404 
 3435.00                ELSE                                                     <ATHA67> 160404 
 3436.00                    MOVE WSAA-CLAW-COMM-REMN                             <ATHA67> 160404 
 3437.00                                        TO WSAA-PAID-COMM-CLAWB          <ATHA67> 160404 
 3438.00                    MOVE WSAA-CLAW-PREM-REMN                             <ATHA67> 160404 
 3439.00                                        TO WSAA-PAID-PREM-CLAWB          <ATHA67> 160404 
 3440.00                    MOVE WSAA-CLAW-OVRC-REMN                             <ATHA67> 160404 
 3441.00                                        TO WSAA-PAID-OVRCOM-CLAWB        <ATHA67> 160404 
 3442.00                END-IF                                                   <ATHA67> 160404 
 3443.00            END-IF                                                       <ATHA67> 160404 
 3444.00            .                                                            <ATHA67> 160404 
 3445.00        X3100-EXIT.                                                      <ATHA67> 160404 
 3446.00            EXIT.                                                        <ATHA67> 160404 
 3447.00       /                                                                 <ATHA67> 160404 
 3448.00        X3200-FIND-CLAWB-REMN-TOPUP SECTION.                             <ATHA67> 160404 
 3449.00       ************************************                              <ATHA67> 160404 
 3450.00        X3200-START.                                                     <ATHA67> 160404 
 3451.00                                                                         <ATHA67> 160404 
 3452.00            COMPUTE WSAA-PRV-CLAW-PREM   = WSAA-PRV-CLAW-PREM            <ATHA67> 160404 
 3453.00                                         * -1                            <ATHA67> 160404 
 3454.00            COMPUTE WSAA-PRV-CLAW-COMM   = WSAA-PRV-CLAW-COMM            <ATHA67> 160404 
 3455.00                                         * -1                            <ATHA67> 160404 
 3456.00            COMPUTE WSAA-PRV-CLAW-OVRC   = WSAA-PRV-CLAW-OVRC            <ATHA67> 160404 
 3457.00                                         * -1                            <ATHA67> 160404 
 3458.00            COMPUTE WSAA-CLAW-PREM-REMN  = WSAA-PAID-PREM                <ATHA67> 160404 
 3459.00                                         - WSAA-PRV-CLAW-PREM            <ATHA67> 160404 
 3460.00            COMPUTE WSAA-CLAW-COMM-REMN  = WSAA-PAID-COMM                <ATHA67> 160404 
 3461.00                                         - WSAA-PRV-CLAW-COMM            <ATHA67> 160404 
 3462.00            COMPUTE WSAA-CLAW-OVRC-REMN  = WSAA-PAID-OVRCOM              <ATHA67> 160404 
 3463.00                                         - WSAA-PRV-CLAW-OVRC            <ATHA67> 160404 
 3464.00                                                                         <ATHA67> 160404 
 3465.00            IF  WSAA-CLAW-COMM-REMN     <  WSAA-CLAWBACK-TOPUP           <ATHA67> 160404 
 3466.00                IF  WSAA-CLAW-COMM-REMN  <= ZEROS                        <ATHA67> 160404 
 3467.00                    MOVE ZEROS          TO WSAA-CLAWBACK-TOPUP           <ATHA67> 160404 
 3468.00                    MOVE ZEROS          TO WSAA-CLAWBACK-NET             <ATHA67> 160404 
 3469.00                    MOVE ZEROS          TO WSAA-CLAWBACK-OVRAMT          <ATHA67> 160404 
 3470.00                ELSE                                                     <ATHA67> 160404 
 3471.00                    MOVE WSAA-CLAW-COMM-REMN                             <ATHA67> 160404 
 3472.00                                        TO WSAA-CLAWBACK-TOPUP           <ATHA67> 160404 
 3473.00                    MOVE WSAA-CLAW-PREM-REMN                             <ATHA67> 160404 
 3474.00                                        TO WSAA-CLAWBACK-NET             <ATHA67> 160404 
 3475.00                    MOVE WSAA-CLAW-OVRC-REMN                             <ATHA67> 160404 
 3476.00                                        TO WSAA-CLAWBACK-OVRAMT          <ATHA67> 160404 
 3477.00                END-IF                                                   <ATHA67> 160404 
 3478.00            END-IF                                                       <ATHA67> 160404 
 3479.00            .                                                            <ATHA67> 160404 
 3480.00        X3200-EXIT.                                                      <ATHA67> 160404 
 3481.00            EXIT.                                                        <ATHA67> 160404 
 3482.00       /                                                                 <ATHB37> 170208 
 3483.00        X3500-FIND-ANNIVERSARY SECTION.                                  <ATHB37> 170208 
 3484.00       ********************************                                  <ATHB37> 170208 
 3485.00        X3500-START.                                                     <ATHB37> 170208 
 3486.00                                                                         <ATHB37> 170208 
 3487.00            MOVE ZEROS                  TO WSAA-COUNT-YEAR               <ATHB37> 170208 
 3488.00            MOVE CHDRMJA-OCCDATE        TO WSAA-NEXT-ANNI-WRK            <ATHB37> 170208 
 3489.00                                                                         <ATHB37> 170208 
 3490.00            PERFORM VARYING WSAA-IND2 FROM 1 BY 1                        <ATHB37> 170210 
 3491.00               UNTIL WSAA-IND2           > WSCC-MAX-ARRAY                <ATHB37> 170208 
 3492.00               OR    WSAA-NEXT-ANNI-WRK  > ZSCLABCK-EFFDATE              <ATHB37> 170208 
 3493.00                                                                         <ATHB37> 170208 
 3494.00                  INITIALIZE DTC4-DATCON4-REC                            <ATHB37> 170208 
 3495.00                  MOVE WSAA-NEXT-ANNI-WRK                                <ATHB37> 170208 
 3496.00                                        TO DTC4-INT-DATE-1               <ATHB37> 170208 
 3497.00                  MOVE WSCC-01          TO DTC4-FREQUENCY                <ATHB37> 170208 
 3498.00                  MOVE 1                TO DTC4-FREQ-FACTOR              <ATHB37> 170208 
 3499.00                                                                         <ATHB37> 170208 
 3500.00                  CALL 'DATCON4'     USING DTC4-DATCON4-REC              <ATHB37> 170208 
 3501.00                                                                         <ATHB37> 170208 
 3502.00                  IF  DTC4-STATUZ    NOT = O-K                           <ATHB37> 170208 
 3503.00                      MOVE DTC4-DATCON4-REC                              <ATHB37> 170208 
 3504.00                                        TO SYSR-PARAMS                   <ATHB37> 170208 
 3505.00                      MOVE DTC4-STATUZ  TO SYSR-STATUZ                   <ATHB37> 170208 
 3506.00                      PERFORM 9000-FATAL-ERROR                           <ATHB37> 170208 
 3507.00                  END-IF                                                 <ATHB37> 170208 
 3508.00                                                                         <ATHB37> 170208 
 3509.00                  IF  DTC4-INT-DATE-2   < ZSCLABCK-EFFDATE               <ATHB37> 170208 
 3510.00                      MOVE DTC4-INT-DATE-2                               <ATHB37> 170208 
 3511.00                                        TO WSAA-TO-DATE-W(WSAA-IND2)     <ATHB37> 170208 
 3512.00                      MOVE WSAA-NEXT-ANNI-WRK                            <ATHB37> 170213 
 3513.00                                        TO WSAA-FROM-DATE-W(WSAA-IND2)   <ATHB37> 170208 
 3514.00                      ADD 1             TO WSAA-COUNT-YEAR               <ATHB37> 170208 
 3515.00                  END-IF                                                 <ATHB37> 170208 
 3516.00                  MOVE DTC4-INT-DATE-2  TO WSAA-NEXT-ANNI-WRK            <ATHB37> 170208 
 3517.00                                                                         <ATHB37> 170208 
 3518.00            END-PERFORM                                                  <ATHB37> 170208 
 3519.00                                                                         <ATHB37> 170208 
 3520.00            IF  WSAA-COUNT-YEAR          = ZEROS                         <ATHB37> 170208 
 3521.00                SET MUST-EXIT-PGM       TO TRUE                          <ATHB37> 170208 
 3522.00            END-IF                                                       <ATHB37> 170208 
 3523.00            .                                                            <ATHB37> 170208 
 3524.00        X3500-EXIT.                                                      <ATHB37> 170208 
 3525.00            EXIT.                                                        <ATHB37> 170208 
 3526.00       /                                                                 <ATHB37> 170210 
 3527.00        X3600-COVRAFI-IO SECTION.                                        <ATHB37> 170210 
 3528.00       *************************                                         <ATHB37> 170210 
 3529.00        X3600-START.                                                     <ATHB37> 170210 
 3530.00                                                                         <ATHB37> 170210 
 3531.00            MOVE COVRAFIREC             TO COVRAFI-FORMAT                <ATHB37> 170210 
 3532.00            CALL 'COVRAFIIO' USING COVRAFI-PARAMS.                       <ATHB37> 170210 
 3533.00                                                                         <ATHB37> 170210 
 3534.00            IF  COVRAFI-STATUZ NOT = O-K                                 <ATHB37> 170210 
 3535.00            AND COVRAFI-STATUZ NOT = ENDP                                <ATHB37> 170210 
 3536.00               MOVE COVRAFI-PARAMS     TO SYSR-PARAMS                    <ATHB37> 170210 
 3537.00               PERFORM 9000-FATAL-ERROR                                  <ATHB37> 170210 
 3538.00            END-IF                                                       <ATHB37> 170210 
 3539.00            IF  COVRAFI-CHDRCOY      NOT = ZSCLABCK-CHDRCOY              <ATHB37> 170210 
 3540.00            OR  COVRAFI-CHDRNUM      NOT = ZSCLABCK-CHDRNUM              <ATHB37> 170210 
 3541.00            OR  COVRAFI-LIFE         NOT = ZSCLABCK-LIFE                 <ATHB37> 170210 
 3542.00            OR  COVRAFI-COVERAGE     NOT = ZSCLABCK-COVERAGE             <ATHB37> 170210 
 3543.00            OR  COVRAFI-RIDER        NOT = ZSCLABCK-RIDER                <ATHB37> 170210 
 3544.00            OR  COVRAFI-PLAN-SUFFIX  NOT = ZSCLABCK-PLAN-SUFFIX          <ATHB37> 170210 
 3545.00                MOVE ENDP               TO COVRAFI-STATUZ                <ATHB37> 170210 
 3546.00            END-IF                                                       <ATHB37> 170210 
 3547.00            .                                                            <ATHB37> 170210 
 3548.00        X3600-EXIT.                                                      <ATHB37> 170210 
 3549.00            EXIT.                                                        <ATHB37> 170210 
 3550.00       /                                                                 <ATHB87> 170824 
 3551.00        X3650-COVRAFI-IO SECTION.                                        <ATHB87> 170824 
 3552.00       *************************                                         <ATHB87> 170824 
 3553.00        X3650-START.                                                     <ATHB87> 170824 
 3554.00                                                                         <ATHB87> 170824 
 3555.00            MOVE COVRAFIREC             TO COVRAFI-FORMAT                <ATHB87> 170824 
 3556.00            CALL 'COVRAFIIO' USING COVRAFI-PARAMS.                       <ATHB87> 170824 
 3557.00                                                                         <ATHB87> 170824 
 3558.00            IF  COVRAFI-STATUZ NOT = O-K                                 <ATHB87> 170824 
 3559.00            AND COVRAFI-STATUZ NOT = ENDP                                <ATHB87> 170824 
 3560.00               MOVE COVRAFI-PARAMS     TO SYSR-PARAMS                    <ATHB87> 170824 
 3561.00               PERFORM 9000-FATAL-ERROR                                  <ATHB87> 170824 
 3562.00            END-IF                                                       <ATHB87> 170824 
 3563.00            IF  COVRAFI-CHDRCOY      NOT = ZSCLABCK-CHDRCOY              <ATHB87> 170824 
 3564.00            OR  COVRAFI-CHDRNUM      NOT = ZSCLABCK-CHDRNUM              <ATHB87> 170824 
 3565.00            OR  COVRAFI-LIFE         NOT = WSAA-ZCLB-LIFE                <ATHB87> 170824 
 3566.00            OR  COVRAFI-COVERAGE     NOT = WSAA-ZCLB-COVERAGE            <ATHB87> 170824 
 3567.00            OR  COVRAFI-RIDER        NOT = WSAA-ZCLB-RIDER               <ATHB87> 170824 
 3568.00            OR  COVRAFI-PLAN-SUFFIX  NOT = ZEROS                         <ATHB87> 170824 
 3569.00                MOVE ENDP               TO COVRAFI-STATUZ                <ATHB87> 170824 
 3570.00            END-IF                                                       <ATHB87> 170824 
 3571.00            .                                                            <ATHB87> 170824 
 3572.00        X3650-EXIT.                                                      <ATHB87> 170824 
 3573.00            EXIT.                                                        <ATHB87> 170824 
 3574.00       /                                                                 <ATHB37> 170210 
 3575.00        X3700-CHDRAFI-IO SECTION.                                        <ATHB37> 170210 
 3576.00       *************************                                         <ATHB37> 170210 
 3577.00        X3700-START.                                                     <ATHB37> 170210 
 3578.00                                                                         <ATHB37> 170210 
 3579.00            MOVE CHDRAFIREC             TO CHDRAFI-FORMAT                <ATHB37> 170210 
 3580.00            CALL 'CHDRAFIIO' USING CHDRAFI-PARAMS.                       <ATHB37> 170210 
 3581.00                                                                         <ATHB37> 170210 
 3582.00            IF  CHDRAFI-STATUZ NOT = O-K                                 <ATHB37> 170210 
 3583.00            AND CHDRAFI-STATUZ NOT = ENDP                                <ATHB37> 170210 
 3584.00               MOVE CHDRAFI-PARAMS     TO SYSR-PARAMS                    <ATHB37> 170210 
 3585.00               PERFORM 9000-FATAL-ERROR                                  <ATHB37> 170210 
 3586.00            END-IF                                                       <ATHB37> 170210 
 3587.00                                                                         <ATHB37> 170210 
 3588.00            IF  CHDRAFI-CHDRCOY      NOT = COVRAFI-CHDRCOY               <ATHB37> 170210 
 3589.00            OR  CHDRAFI-CHDRNUM      NOT = COVRAFI-CHDRNUM               <ATHB37> 170210 
 3590.00                MOVE ENDP               TO CHDRAFI-STATUZ                <ATHB37> 170210 
 3591.00            END-IF                                                       <ATHB37> 170210 
 3592.00            .                                                            <ATHB37> 170210 
 3593.00        X3700-EXIT.                                                      <ATHB37> 170210 
 3594.00            EXIT.                                                        <ATHB37> 170210 
 3595.00       /                                                                 <ATHB37> 170213 
 3596.00        X4000-CALL-ITDM-IO SECTION.                                      <ATHB37> 170213 
 3597.00       ***************************                                       <ATHB37> 170213 
 3598.00        X4000-START.                                                     <ATHB37> 170213 
 3599.00                                                                         <ATHB37> 170213 
 3600.00            MOVE O-K                    TO ITDM-STATUZ                   <ATHB37> 170213 
 3601.00            MOVE ITDMREC                TO ITDM-FORMAT                   <ATHB37> 170213 
 3602.00                                                                         <ATHB37> 170213 
 3603.00            CALL 'ITDMIO'            USING ITDM-PARAMS                   <ATHB37> 170213 
 3604.00                                                                         <ATHB37> 170213 
 3605.00            IF  ITDM-STATUZ          NOT = O-K                           <ATHB37> 170213 
 3606.00            AND ITDM-STATUZ          NOT = ENDP                          <ATHB37> 170213 
 3607.00                MOVE ITDM-STATUZ        TO SYSR-STATUZ                   <ATHB37> 170213 
 3608.00                MOVE ITDM-PARAMS        TO SYSR-PARAMS                   <ATHB37> 170213 
 3609.00                PERFORM 9000-FATAL-ERROR                                 <ATHB37> 170214 
 3610.00            END-IF                                                       <ATHB37> 170213 
 3611.00            .                                                            <ATHB37> 170213 
 3612.00        X4000-EXIT.                                                      <ATHB37> 170213 
 3613.00            EXIT.                                                        <ATHB37> 170213 
 3614.00       /                                                                 <ATHB37> 170214 
 3615.00        X4100-READ-T7Z11 SECTION.                                        <ATHB37> 170214 
 3616.00       ***************************                                       <ATHB37> 170214 
 3617.00        X4100-START.                                                     <ATHB37> 170214 
 3618.00            MOVE SPACES                 TO ITDM-DATA-KEY                 <ATHB37> 170214 
 3619.00            MOVE ZSCLABCK-CHDRCOY       TO ITDM-ITEMCOY                  <ATHB37> 170214 
 3620.00            MOVE T7Z11                  TO ITDM-ITEMTABL                 <ATHB37> 170214 
 3621.00            MOVE WSAA-ITEMITEM-IT       TO ITDM-ITEMITEM                 <ATHB37> 170214 
 3622.00            MOVE COVRAFI-CRRCD          TO ITDM-ITMFRM                   <ATHB37> 170214 
 3623.00            MOVE ITDMREC                TO ITDM-FORMAT                   <ATHB37> 170214 
 3624.00                                                                         <ATHB37> 170214 
 3625.00            MOVE BEGN                   TO ITDM-FUNCTION                 <ATHB37> 170214 
 3626.00                                                                         <ATHB37> 170214 
 3627.00            CALL 'ITDMIO'            USING ITDM-PARAMS                   <ATHB37> 170214 
 3628.00                                                                         <ATHB37> 170214 
 3629.00            IF  ITDM-STATUZ          NOT = O-K                           <ATHB37> 170214 
 3630.00            AND ITDM-STATUZ          NOT = ENDP                          <ATHB37> 170214 
 3631.00                MOVE ITDM-PARAMS        TO SYSR-PARAMS                   <ATHB37> 170214 
 3632.00                PERFORM 9000-FATAL-ERROR                                 <ATHB37> 170214 
 3633.00            END-IF                                                       <ATHB37> 170214 
 3634.00                                                                         <ATHB37> 170214 
 3635.00            IF  ITDM-ITEMCOY         NOT = ZSCLABCK-CHDRCOY              <ATHB37> 170214 
 3636.00            OR  ITDM-ITEMTABL        NOT = T7Z11                         <ATHB37> 170214 
 3637.00            OR  ITDM-ITEMITEM        NOT = WSAA-ITEMITEM-IT              <ATHB37> 170214 
 3638.00            OR  ITDM-STATUZ              = ENDP                          <ATHB37> 170214 
 3639.00                MOVE COVRAFI-CHDRNUM    TO SYSR-PARAMS                   <ATHB37> 170214 
 3640.00                PERFORM 9000-FATAL-ERROR                                 <ATHB37> 170214 
 3641.00            ELSE                                                         <ATHB37> 170214 
 3642.00                MOVE ITDM-GENAREA       TO T7Z11-T7Z11-REC               <ATHB37> 170214 
 3643.00            END-IF                                                       <ATHB37> 170214 
 3644.00            .                                                            <ATHB37> 170214 
 3645.00        X4100-EXIT.                                                      <ATHB37> 170214 
 3646.00            EXIT.                                                        <ATHB37> 170214 
 3647.00       /                                                                 <ATHB37> 170214 
 3648.00        X4150-GET-T7Z11 SECTION.                                         <ATHB37> 170214 
 3649.00       ************************                                          <ATHB37> 170214 
 3650.00        X4150-START.                                                     <ATHB37> 170214 
 3651.00                                                                         <ATHB37> 170214 
 3652.00            IF COVRAFI-RISK-CESS-TERM    > 20                            <ATHB37> 170214 
 3653.00               MOVE 20                  TO WSAA-CESS-TERM                <ATHB37> 170214 
 3654.00            ELSE                                                         <ATHB37> 170214 
 3655.00               MOVE COVRAFI-RISK-CESS-TERM                               <ATHB37> 170214 
 3656.00                                        TO WSAA-CESS-TERM                <ATHB37> 170214 
 3657.00            END-IF                                                       <ATHB37> 170214 
 3658.00            PERFORM X4155-MATCH-DURATION                                 <ATHB37> 170214 
 3659.00                    VARYING WSAA-ARRAY-INDEX FROM 1 BY 1                 <ATHB37> 170214 
 3660.00                            UNTIL WSAA-ARRAY-INDEX = 11                  <ATHB37> 170214 
 3661.00                            OR T7Z11-ZDUR(WSAA-ARRAY-INDEX)              <ATHB37> 170214 
 3662.00                            = WSAA-CESS-TERM                             <ATHB37> 170214 
 3663.00            MOVE 1                      TO WSAA-TERMW                    <ATHB37> 170215 
 3664.00            IF  WSAA-TERMW               = 0                             <ATHB37> 170214 
 3665.00                MOVE 1                  TO WSAA-TERMW                    <ATHB37> 170214 
 3666.00            END-IF                                                       <ATHB37> 170214 
 3667.00            COMPUTE WSAA-ARRAY-INDEX2    = WSAA-TERMW                    <ATHB37> 170214 
 3668.00                                         + ((6 * WSAA-ARRAY-INDEX) - 6)  <ATHB37> 170214 
 3669.00                                                                         <ATHB37> 170214 
 3670.00            IF  WSAA-ARRAY-INDEX2        > (6 * WSAA-ARRAY-INDEX)        <ATHB37> 170214 
 3671.00                MOVE ZEROS              TO WSAA-T7Z11                    <ATHB37> 170214 
 3672.00            ELSE                                                         <ATHB37> 170214 
 3673.00                MOVE T7Z11-ZCOMRAT(WSAA-ARRAY-INDEX2)                    <ATHB37> 170214 
 3674.00                                        TO WSAA-T7Z11                    <ATHB37> 170214 
 3675.00            END-IF                                                       <ATHB37> 170214 
 3676.00            .                                                            <ATHB37> 170214 
 3677.00        X4150-EXIT.                                                      <ATHB37> 170214 
 3678.00            EXIT.                                                        <ATHB37> 170214 
 3679.00       /                                                                 <ATHB37> 170214 
 3680.00        X4155-MATCH-DURATION SECTION.                                    <ATHB37> 170214 
 3681.00       ****************************                                      <ATHB37> 170214 
 3682.00        X4155-START.                                                     <ATHB37> 170214 
 3683.00       * DUMMY                                                           <ATHB37> 170214 
 3684.00        X4155-EXIT.                                                      <ATHB37> 170214 
 3685.00            EXIT.                                                        <ATHB37> 170214 
 3686.00       *                                                                 <ATHD11> 181019 
 3687.00        X4250-READ-T8Z05 SECTION.                                        <ATHD11> 181019 
 3688.00       *********************************                                 <ATHD11> 181019 
 3689.00        X4250-START.                                                     <ATHD11> 181019 
 3690.00       *                                                                 <ATHD11> 181019 
 3691.00            SET NOT-MCPPI-PRODUCT       TO TRUE                          <ATHD11> 181019 
 3692.00                                                                         <ATHD11> 181019 
 3693.00            MOVE SPACES                 TO ITDM-DATA-AREA                <ATHD11> 181019 
 3694.00                                                                         <ATHD11> 181019 
 3695.00            MOVE 'IT'                   TO ITDM-ITEMPFX                  <ATHD11> 181019 
 3696.00            MOVE ZSCLABCK-CHDRCOY       TO ITDM-ITEMCOY                  <ATHD11> 181019 
 3697.00            MOVE T8Z05                  TO ITDM-ITEMTABL                 <ATHD11> 181019 
 3698.00            MOVE CHDRMJA-OCCDATE        TO ITDM-ITMFRM                   <ATHD11> 181019 
 3699.00            MOVE CHDRMJA-CNTTYPE        TO ITDM-ITEMITEM                 <ATHD11> 181019 
 3700.00            MOVE BEGN                   TO ITDM-FUNCTION                 <ATHD11> 181019 
 3701.00                                                                         <ATHD11> 181019 
 3702.00            CALL 'ITDMIO' USING         ITDM-PARAMS                      <ATHD11> 181019 
 3703.00                                                                         <ATHD11> 181019 
 3704.00            IF ITDM-STATUZ              NOT = O-K  AND                   <ATHD11> 181019 
 3705.00               ITDM-STATUZ              NOT = ENDP                       <ATHD11> 181019 
 3706.00                MOVE ITDM-PARAMS        TO SYSR-PARAMS                   <ATHD11> 181019 
 3707.00                MOVE ITDM-STATUZ        TO SYSR-STATUZ                   <ATHD11> 181019 
 3708.00                PERFORM 9000-FATAL-ERROR                                 <ATHD11> 181019 
 3709.00                                                                         <ATHD11> 181019 
 3710.00            IF ITDM-ITEMCOY             NOT = ZSCLABCK-CHDRCOY OR        <ATHD11> 181019 
 3711.00               ITDM-ITEMTABL            NOT = T8Z05 OR                   <ATHD11> 181019 
 3712.00               ITDM-ITEMITEM            NOT = CHDRMJA-CNTTYPE OR         <ATHD11> 181019 
 3713.00               ITDM-STATUZ              = ENDP                           <ATHD11> 181019 
 3714.00                GO TO X4250-EXIT                                         <ATHD11> 181019 
 3715.00            ELSE                                                         <ATHD11> 181019 
 3716.00                SET MCPPI-PRODUCT       TO TRUE                          <ATHD11> 181019 
 3717.00            END-IF                                                       <ATHD11> 181019 
 3718.00            .                                                            <ATHD11> 181019 
 3719.00       *                                                                 <ATHD11> 181019 
 3720.00        X4250-EXIT.                                                      <ATHD11> 181019 
 3721.00            EXIT.                                                        <ATHD11> 181019 
 3722.00       /                                                                 <ATHB37> 170214 
 3723.00        X4200-READ-T5Z01 SECTION.                                        <ATHB37> 170214 
 3724.00       *************************                                         <ATHB37> 170214 
 3725.00        X4200-START.                                                     <ATHB37> 170214 
 3726.00                                                                         <ATHB37> 170214 
 3727.00            INITIALIZE T5Z01-T5Z01-REC                                   <ATHB37> 170214 
 3728.00            MOVE SPACES                TO ITEM-PARAMS                    <ATHB37> 170214 
 3729.00            MOVE SMTP-ITEM             TO ITEM-ITEMPFX                   <ATHB37> 170214 
 3730.00            MOVE ZSCLABCK-CHDRCOY      TO ITEM-ITEMCOY                   <ATHB37> 170214 
 3731.00            MOVE T5Z01                 TO ITEM-ITEMTABL                  <ATHB37> 170214 
 3732.00            MOVE COVRAFI-CRTABLE       TO ITEM-ITEMITEM                  <ATHB37> 170214 
 3733.00                                                                         <ATHB37> 170214 
 3734.00            MOVE READR                 TO ITEM-FUNCTION                  <ATHB37> 170214 
 3735.00                                                                         <ATHB37> 170214 
 3736.00            CALL 'ITEMIO'              USING ITEM-PARAMS                 <ATHB37> 170214 
 3737.00                                                                         <ATHB37> 170214 
 3738.00            IF  ITEM-STATUZ            NOT = O-K                         <ATHB37> 170214 
 3739.00            AND ITEM-STATUZ            NOT = MRNF                        <ATHB37> 170214 
 3740.00               MOVE ITEM-PARAMS        TO SYSR-PARAMS                    <ATHB37> 170214 
 3741.00               MOVE ITEM-STATUZ        TO SYSR-STATUZ                    <ATHB37> 170214 
 3742.00               PERFORM 9000-FATAL-ERROR                                  <ATHB37> 170214 
 3743.00            END-IF                                                       <ATHB37> 170214 
 3744.00                                                                         <ATHB37> 170214 
 3745.00            IF  ITEM-STATUZ             = O-K                            <ATHB37> 170214 
 3746.00                MOVE ITEM-GENAREA      TO T5Z01-T5Z01-REC                <ATHB37> 170214 
 3747.00            END-IF                                                       <ATHB37> 170214 
 3748.00            .                                                            <ATHB37> 170214 
 3749.00        X4200-EXIT.                                                      <ATHB37> 170214 
 3750.00            EXIT.                                                        <ATHB37> 170214 
 3751.00       /                                                                 <ATHB37> 170302 
 3752.00        X4300-READ-T5694 SECTION.                                        <ATHB37> 170302 
 3753.00       ***************************                                       <ATHB37> 170302 
 3754.00        X4300-START.                                                     <ATHB37> 170302 
 3755.00            MOVE SPACES                 TO ITDM-DATA-KEY                 <ATHB37> 170302 
 3756.00            MOVE ZSCLABCK-CHDRCOY       TO ITDM-ITEMCOY                  <ATHB37> 170302 
 3757.00            MOVE T5694                  TO ITDM-ITEMTABL                 <ATHB37> 170302 
 3758.00            MOVE WSAA-METHOD-IT         TO ITDM-ITEMITEM                 <ATHB37> 181019 
 3759.00            MOVE COVRAFI-CRRCD          TO ITDM-ITMFRM                   <ATHB37> 170302 
 3760.00            MOVE ITDMREC                TO ITDM-FORMAT                   <ATHB37> 170302 
 3761.00                                                                         <ATHB37> 170302 
 3762.00            MOVE BEGN                   TO ITDM-FUNCTION                 <ATHB37> 170302 
 3763.00                                                                         <ATHB37> 170302 
 3764.00            CALL 'ITDMIO'            USING ITDM-PARAMS                   <ATHB37> 170302 
 3765.00                                                                         <ATHB37> 170302 
 3766.00            IF  ITDM-STATUZ          NOT = O-K                           <ATHB37> 170302 
 3767.00            AND ITDM-STATUZ          NOT = ENDP                          <ATHB37> 170302 
 3768.00                MOVE ITDM-PARAMS        TO SYSR-PARAMS                   <ATHB37> 170302 
 3769.00                PERFORM 9000-FATAL-ERROR                                 <ATHB37> 170302 
 3770.00            END-IF                                                       <ATHB37> 170302 
 3771.00                                                                         <ATHB37> 170302 
 3772.00            IF  ITDM-ITEMCOY         NOT = ZSCLABCK-CHDRCOY              <ATHB37> 170302 
 3773.00            OR  ITDM-ITEMTABL        NOT = T5694                         <ATHB37> 170302 
 3774.00       **** OR  ITDM-ITEMITEM        NOT = T5Z01-ZAACPY          <ATHD11><ATHB37> 181023 
 3775.00            OR  ITDM-ITEMITEM        NOT = WSAA-METHOD-IT                <ATHD11> 181023 
 3776.00            OR  ITDM-STATUZ              = ENDP                          <ATHB37> 170302 
 3777.00                MOVE COVRAFI-CHDRNUM    TO SYSR-PARAMS                   <ATHB37> 170302 
 3778.00                PERFORM 9000-FATAL-ERROR                                 <ATHB37> 170302 
 3779.00            ELSE                                                         <ATHB37> 170302 
 3780.00                MOVE ITDM-GENAREA       TO T5694-T5694-REC               <ATHB37> 170302 
 3781.00            END-IF                                                       <ATHB37> 170302 
 3782.00            .                                                            <ATHB37> 170302 
 3783.00        X4300-EXIT.                                                      <ATHB37> 170302 
 3784.00            EXIT.                                                        <ATHB37> 170302 
 3785.00       /                                                                 <ATHB37> 170302 
 3786.00        X4350-GET-T5694 SECTION.                                         <ATHB37> 170302 
 3787.00       ************************                                          <ATHB37> 170302 
 3788.00        X4350-START.                                                     <ATHB37> 170302 
 3789.00                                                                         <ATHB37> 170302 
 3790.00       *  Access table value based on WSAA-TERM                          <ATHB37> 170302 
 3791.00                                                                         <ATHB37> 170302 
 3792.00            IF  WSAA-TERMW           NOT > T5694-TO-YEAR(WSAA-INDEX)     <ATHB37> 170302 
 3793.00                MOVE T5694-INSTALPC(WSAA-INDEX)                          <ATHB37> 170302 
 3794.00                                        TO WSAA-T5694                    <ATHB37> 170302 
 3795.00                MOVE 13                 TO WSAA-INDEX                    <ATHB37> 170302 
 3796.00            END-IF                                                       <ATHB37> 170302 
 3797.00            .                                                            <ATHB37> 170302 
 3798.00        X4350-EXIT.                                                      <ATHB37> 170302 
 3799.00            EXIT.                                                        <ATHB37> 170302 
 3800.00       /                                                                 <ATHB45> 170313 
 3801.00        X4400-GET-TU-COVR SECTION.                                       <ATHB45> 170313 
 3802.00       **************************                                        <ATHB45> 170313 
 3803.00        X4400-START.                                                     <ATHB45> 170313 
 3804.00                                                                         <ATHB45> 170313 
 3805.00            MOVE SPACES                 TO WSAA-TU-CRTABLE               <ATHB45> 170313 
 3806.00                                                                         <ATHB45> 170313 
 3807.00            MOVE CHDRMJA-CNTTYPE        TO WSAA-T5673-ITEM               <ATHB45> 170313 
 3808.00            PERFORM X4500-READ-T5673                                     <ATHB45> 170313 
 3809.00            IF  ITDM-STATUZ          NOT = O-K                           <ATHB45> 170313 
 3810.00                GO TO X4400-EXIT                                         <ATHB45> 170313 
 3811.00            END-IF                                                       <ATHB45> 170313 
 3812.00                                                                         <ATHB45> 170313 
 3813.00            SET NOT-MUST-EXIT-LOOP      TO TRUE                          <ATHB45> 170313 
 3814.00            PERFORM                                                      <ATHB45> 170313 
 3815.00              UNTIL MUST-EXIT-LOOP                                       <ATHB45> 170313 
 3816.00                PERFORM X4410-GET-TU-COVR-MAIN                           <ATHB45> 170313 
 3817.00                                                                         <ATHB45> 170313 
 3818.00                IF  WSAA-TU-CRTABLE  NOT = SPACES                        <ATHB45> 170313 
 3819.00                    SET MUST-EXIT-LOOP  TO TRUE                          <ATHB45> 170313 
 3820.00                END-IF                                                   <ATHB45> 170313 
 3821.00                IF  T5673-GITEM          = SPACES                        <ATHB45> 170313 
 3822.00                    SET MUST-EXIT-LOOP  TO TRUE                          <ATHB45> 170313 
 3823.00                END-IF                                                   <ATHB45> 170313 
 3824.00                IF  NOT MUST-EXIT-LOOP                                   <ATHB45> 170313 
 3825.00                    MOVE T5673-GITEM    TO WSAA-T5673-ITEM               <ATHB45> 170313 
 3826.00                    PERFORM X4500-READ-T5673                             <ATHB45> 170313 
 3827.00                END-IF                                                   <ATHB45> 170313 
 3828.00            END-PERFORM                                                  <ATHB45> 170313 
 3829.00            .                                                            <ATHB45> 170313 
 3830.00        X4400-EXIT.                                                      <ATHB45> 170313 
 3831.00            EXIT.                                                        <ATHB45> 170313 
 3832.00       /                                                                 <ATHB45> 170313 
 3833.00        X4410-GET-TU-COVR-MAIN SECTION.                                  <ATHB45> 170313 
 3834.00       *******************************                                   <ATHB45> 170313 
 3835.00        X4410-START.                                                     <ATHB45> 170313 
 3836.00                                                                         <ATHB45> 170313 
 3837.00            PERFORM VARYING WSAA-IND1 FROM 1 BY 1                        <ATHB45> 170313 
 3838.00              UNTIL WSAA-TU-CRTABLE  NOT = SPACES                        <ATHB45> 170313 
 3839.00              OR    T5673-CTABLE (WSAA-IND1)                             <ATHB45> 170313 
 3840.00                                         = SPACES                        <ATHB45> 170313 
 3841.00                PERFORM X4450-GET-CRTABLE-TYPE                           <ATHB45> 170313 
 3842.00                IF  CRTABLE-TYPE-TOP-UP                                  <ATHB45> 170313 
 3843.00                AND T5673-CTABLE(WSAA-IND1)                              <ATHB45> 170313 
 3844.00                                     NOT = 'TULB'                        <ATHB45> 170313 
 3845.00                AND T5673-CTABLE(WSAA-IND1)                              <ATHB45> 170313 
 3846.00                                     NOT = 'TULA'                        <ATHB45> 170313 
 3847.00                    MOVE T5673-CTABLE (WSAA-IND1)                        <ATHB45> 170313 
 3848.00                                        TO WSAA-TU-CRTABLE               <ATHB45> 170313 
 3849.00                END-IF                                                   <ATHB45> 170313 
 3850.00            END-PERFORM                                                  <ATHB45> 170313 
 3851.00            .                                                            <ATHB45> 170313 
 3852.00        X4410-EXIT.                                                      <ATHB45> 170313 
 3853.00            EXIT.                                                        <ATHB45> 170313 
 3854.00       /                                                                 <ATHB45> 170313 
 3855.00        X4450-GET-CRTABLE-TYPE SECTION.                                  <ATHB45> 170313 
 3856.00       *******************************                                   <ATHB45> 170313 
 3857.00        X4450-START.                                                     <ATHB45> 170313 
 3858.00                                                                         <ATHB45> 170313 
 3859.00            MOVE SPACES                 TO WS88-CRTABLE-TYPE             <ATHB45> 170313 
 3860.00                                                                         <ATHB45> 170313 
 3861.00            MOVE T5673-CTABLE (WSAA-IND1)                                <ATHB45> 170313 
 3862.00                                        TO WSAA-READ-CRTABLE             <ATHB45> 170313 
 3863.00            PERFORM X4700-READ-T5687                                     <ATHB45> 170313 
 3864.00            IF  ITDM-STATUZ          NOT = O-K                           <ATHB45> 170313 
 3865.00                GO TO X4450-EXIT                                         <ATHB45> 170313 
 3866.00            END-IF                                                       <ATHB45> 170313 
 3867.00            MOVE T5687-ZCOMPONENT-TYPE  TO WS88-CRTABLE-TYPE             <ATHB45> 170313 
 3868.00            .                                                            <ATHB45> 170313 
 3869.00        X4450-EXIT.                                                      <ATHB45> 170313 
 3870.00            EXIT.                                                        <ATHB45> 170313 
 3871.00       /                                                                 <ATHB45> 170313 
 3872.00        X4500-READ-T5673 SECTION.                                        <ATHB45> 170313 
 3873.00       *************************                                         <ATHB45> 170313 
 3874.00        X4500-START.                                                     <ATHB45> 170313 
 3875.00                                                                         <ATHB45> 170313 
 3876.00            INITIALIZE T5673-T5673-REC                                   <ATHB45> 170313 
 3877.00                                                                         <ATHB45> 170313 
 3878.00            INITIALIZE ITDM-PARAMS                                       <ATHB45> 170313 
 3879.00            INITIALIZE ITEMREC-KEY-DATA     OF ITDM-PARAMS               <ATHB45> 170313 
 3880.00            INITIALIZE ITEMREC-NON-KEY-DATA OF ITDM-PARAMS               <ATHB45> 170313 
 3881.00                                                                         <ATHB45> 170313 
 3882.00            MOVE SMTP-ITEM              TO ITDM-ITEMPFX                  <ATHB45> 170313 
 3883.00            MOVE ZSCLABCK-CHDRCOY       TO ITDM-ITEMCOY                  <ATHB45> 170313 
 3884.00            MOVE T5673                  TO ITDM-ITEMTABL                 <ATHB45> 170313 
 3885.00            MOVE WSAA-T5673-ITEM        TO ITDM-ITEMITEM                 <ATHB45> 170313 
 3886.00            MOVE ZSCLABCK-EFFDATE       TO ITDM-ITMFRM                   <ATHB45> 170313 
 3887.00                                                                         <ATHB45> 170313 
 3888.00            MOVE ITDM-DATA-KEY          TO WSAA-ITDMKEY                  <ATHB45> 170313 
 3889.00                                                                         <ATHB45> 170313 
 3890.00            MOVE BEGN                   TO ITDM-FUNCTION                 <ATHB45> 170313 
 3891.00            PERFORM X4600-CALL-ITDM-IO                                   <ATHB45> 170313 
 3892.00                                                                         <ATHB45> 170313 
 3893.00            IF  ITDM-ITEMPFX         NOT = SMTP-ITEM                     <ATHB45> 170313 
 3894.00            OR  ITDM-ITEMCOY         NOT = ZSCLABCK-CHDRCOY              <ATHB45> 170313 
 3895.00            OR  ITDM-ITEMTABL        NOT = T5673                         <ATHB45> 170313 
 3896.00            OR  ITDM-ITEMITEM        NOT = WSAA-T5673-ITEM               <ATHB45> 170313 
 3897.00                MOVE ENDP               TO ITDM-STATUZ                   <ATHB45> 170313 
 3898.00            END-IF                                                       <ATHB45> 170313 
 3899.00                                                                         <ATHB45> 170313 
 3900.00            IF  ITDM-STATUZ          NOT = O-K                           <ATHB45> 170313 
 3901.00                GO TO X4500-EXIT                                         <ATHB45> 170313 
 3902.00            END-IF                                                       <ATHB45> 170313 
 3903.00            MOVE ITDM-GENAREA           TO T5673-T5673-REC               <ATHB45> 170313 
 3904.00            .                                                            <ATHB45> 170313 
 3905.00        X4500-EXIT.                                                      <ATHB45> 170313 
 3906.00            EXIT.                                                        <ATHB45> 170313 
 3907.00       /                                                                 <ATHB45> 170313 
 3908.00        X4600-CALL-ITDM-IO SECTION.                                      <ATHB45> 170313 
 3909.00       ***************************                                       <ATHB45> 170313 
 3910.00        X4600-START.                                                     <ATHB45> 170313 
 3911.00                                                                         <ATHB45> 170313 
 3912.00            MOVE O-K                    TO ITDM-STATUZ                   <ATHB45> 170313 
 3913.00            MOVE ITDMREC                TO ITDM-FORMAT                   <ATHB45> 170313 
 3914.00                                                                         <ATHB45> 170313 
 3915.00            CALL 'ITDMIO'            USING ITDM-PARAMS                   <ATHB45> 170313 
 3916.00                                                                         <ATHB45> 170313 
 3917.00            IF  ITDM-STATUZ          NOT = O-K                           <ATHB45> 170313 
 3918.00            AND ITDM-STATUZ          NOT = ENDP                          <ATHB45> 170313 
 3919.00                MOVE ITDM-STATUZ        TO SYSR-STATUZ                   <ATHB45> 170313 
 3920.00                MOVE ITDM-PARAMS        TO SYSR-PARAMS                   <ATHB45> 170313 
 3921.00                MOVE WSCC-TXT-2         TO SYSR-SYSERR-TYPE              <ATHB45> 170313 
 3922.00                PERFORM 9000-FATAL-ERROR                                 <ATHB45> 170313 
 3923.00            END-IF                                                       <ATHB45> 170313 
 3924.00            .                                                            <ATHB45> 170313 
 3925.00        X4600-EXIT.                                                      <ATHB45> 170313 
 3926.00            EXIT.                                                        <ATHB45> 170313 
 3927.00       /                                                                 <ATHB45> 170313 
 3928.00        X4700-READ-T5687 SECTION.                                        <ATHB45> 170313 
 3929.00       *************************                                         <ATHB45> 170313 
 3930.00        X4700-START.                                                     <ATHB45> 170313 
 3931.00                                                                         <ATHB45> 170313 
 3932.00            INITIALIZE T5687-T5687-REC                                   <ATHB45> 170313 
 3933.00                                                                         <ATHB45> 170313 
 3934.00            INITIALIZE ITDM-PARAMS                                       <ATHB45> 170313 
 3935.00            INITIALIZE ITEMREC-KEY-DATA     OF ITDM-PARAMS               <ATHB45> 170313 
 3936.00            INITIALIZE ITEMREC-NON-KEY-DATA OF ITDM-PARAMS               <ATHB45> 170313 
 3937.00                                                                         <ATHB45> 170313 
 3938.00            MOVE SMTP-ITEM              TO ITDM-ITEMPFX                  <ATHB45> 170313 
 3939.00            MOVE ZSCLABCK-CHDRCOY       TO ITDM-ITEMCOY                  <ATHB45> 170313 
 3940.00            MOVE T5687                  TO ITDM-ITEMTABL                 <ATHB45> 170313 
 3941.00            MOVE WSAA-READ-CRTABLE      TO ITDM-ITEMITEM                 <ATHB45> 170313 
 3942.00            MOVE ZSCLABCK-EFFDATE       TO ITDM-ITMFRM                   <ATHB45> 170313 
 3943.00                                                                         <ATHB45> 170313 
 3944.00            MOVE ITDM-DATA-KEY          TO WSAA-ITDMKEY                  <ATHB45> 170313 
 3945.00                                                                         <ATHB45> 170313 
 3946.00            MOVE BEGN                   TO ITDM-FUNCTION                 <ATHB45> 170313 
 3947.00            PERFORM X4600-CALL-ITDM-IO                                   <ATHB45> 170313 
 3948.00                                                                         <ATHB45> 170313 
 3949.00            IF  ITDM-ITEMPFX         NOT = SMTP-ITEM                     <ATHB45> 170313 
 3950.00            OR  ITDM-ITEMCOY         NOT = ZSCLABCK-CHDRCOY              <ATHB45> 170313 
 3951.00            OR  ITDM-ITEMTABL        NOT = T5687                         <ATHB45> 170313 
 3952.00            OR  ITDM-ITEMITEM        NOT = WSAA-READ-CRTABLE             <ATHB45> 170313 
 3953.00                MOVE ENDP               TO ITDM-STATUZ                   <ATHB45> 170313 
 3954.00            END-IF                                                       <ATHB45> 170313 
 3955.00                                                                         <ATHB45> 170313 
 3956.00            IF  ITDM-STATUZ          NOT = O-K                           <ATHB45> 170313 
 3957.00                GO TO X4700-EXIT                                         <ATHB45> 170313 
 3958.00            END-IF                                                       <ATHB45> 170313 
 3959.00            MOVE ITDM-GENAREA           TO T5687-T5687-REC               <ATHB45> 170313 
 3960.00            .                                                            <ATHB45> 170313 
 3961.00        X4700-EXIT.                                                      <ATHB45> 170313 
 3962.00            EXIT.                                                        <ATHB45> 170313 
 3963.00       /                                                                 <ATHB45> 170310 
 3964.00        X4800-READ-ZCOVCRT SECTION.                                      <ATHB45> 170310 
 3965.00       ***************************                                       <ATHB45> 170310 
 3966.00        X4800-START.                                                     <ATHB45> 170310 
 3967.00                                                                         <ATHB45> 170310 
 3968.00            INITIALIZE ZCOVCRT-PARAMS                                    <ATHB45> 170310 
 3969.00            INITIALIZE ZCOVCRTREC-KEY-DATA     OF ZCOVCRT-PARAMS         <ATHB45> 170310 
 3970.00            INITIALIZE ZCOVCRTREC-NON-KEY-DATA OF ZCOVCRT-PARAMS         <ATHB45> 170310 
 3971.00                                                                         <ATHB45> 170310 
 3972.00            MOVE ZSCLABCK-CHDRCOY       TO ZCOVCRT-CHDRCOY               <ATHB45> 170310 
 3973.00            MOVE WSAA-TU-CRTABLE        TO ZCOVCRT-CRTABLE               <ATHB45> 170310 
 3974.00            MOVE ZSCLABCK-CHDRNUM       TO ZCOVCRT-CHDRNUM               <ATHB45> 170310 
 3975.00                                                                         <ATHB45> 170310 
 3976.00            MOVE BEGN                   TO ZCOVCRT-FUNCTION              <ATHB45> 170310 
 3977.00            PERFORM X4850-ZCOVCRT-IO                                     <ATHB45> 170310 
 3978.00            IF  ZCOVCRT-STATUZ           = O-K                           <ATHB45> 170313 
 3979.00                MOVE ZCOVCRT-LIFE           TO WSAA-TU-LIFE              <ATHB45> 170313 
 3980.00                MOVE ZCOVCRT-COVERAGE       TO WSAA-TU-COVERAGE          <ATHB45> 170313 
 3981.00                MOVE ZCOVCRT-RIDER          TO WSAA-TU-RIDER             <ATHB45> 170313 
 3982.00            ELSE                                                         <ATHB45> 170313 
 3983.00                MOVE '01'                   TO WSAA-TU-LIFE              <ATHB45> 170313 
 3984.00                MOVE '02'                   TO WSAA-TU-COVERAGE          <ATHB45> 170313 
 3985.00                MOVE '00'                   TO WSAA-TU-RIDER             <ATHB45> 170313 
 3986.00            END-IF                                                       <ATHB45> 170313 
 3987.00            .                                                            <ATHB45> 170310 
 3988.00        X4800-EXIT.                                                      <ATHB45> 170310 
 3989.00            EXIT.                                                        <ATHB45> 170310 
 3990.00       /                                                                 <ATHB45> 170310 
 3991.00        X4850-ZCOVCRT-IO SECTION.                                        <ATHB45> 170310 
 3992.00       *************************                                         <ATHB45> 170310 
 3993.00        X4850-START.                                                     <ATHB45> 170310 
 3994.00                                                                         <ATHB45> 170310 
 3995.00            MOVE O-K                    TO ZCOVCRT-STATUZ                <ATHB45> 170310 
 3996.00            MOVE ZCOVCRTREC             TO ZCOVCRT-FORMAT                <ATHB45> 170310 
 3997.00                                                                         <ATHB45> 170310 
 3998.00            CALL 'ZCOVCRTIO'         USING ZCOVCRT-PARAMS                <ATHB45> 170310 
 3999.00                                                                         <ATHB45> 170310 
 4000.00            IF  ZCOVCRT-STATUZ       NOT = O-K                           <ATHB45> 170310 
 4001.00            AND ZCOVCRT-STATUZ       NOT = ENDP                          <ATHB45> 170310 
 4002.00                MOVE ZCOVCRT-STATUZ     TO SYSR-STATUZ                   <ATHB45> 170310 
 4003.00                MOVE ZCOVCRT-PARAMS     TO SYSR-PARAMS                   <ATHB45> 170310 
 4004.00                MOVE WSCC-TXT-2         TO SYSR-SYSERR-TYPE              <ATHB45> 170310 
 4005.00                PERFORM 9000-FATAL-ERROR                                 <ATHB45> 170310 
 4006.00            END-IF                                                       <ATHB45> 170310 
 4007.00                                                                         <ATHB45> 170310 
 4008.00            IF  ZSCLABCK-CHDRCOY     NOT = ZCOVCRT-CHDRCOY               <ATHB45> 170310 
 4009.00            OR  WSAA-TU-CRTABLE      NOT = ZCOVCRT-CRTABLE               <ATHB45> 170310 
 4010.00            OR  ZSCLABCK-CHDRNUM     NOT = ZCOVCRT-CHDRNUM               <ATHB45> 170310 
 4011.00                MOVE ENDP               TO ZCOVCRT-STATUZ                <ATHB45> 170310 
 4012.00            END-IF                                                       <ATHB45> 170310 
 4013.00            .                                                            <ATHB45> 170310 
 4014.00        X4850-EXIT.                                                      <ATHB45> 170310 
 4015.00            EXIT.                                                        <ATHB45> 170310 
 4016.00       /                                                                 <ATHB87> 170824 
 4017.00        X5000-FIND-MAIN-COVR SECTION.                                    <ATHB87> 170824 
 4018.00       ******************************                                    <ATHB87> 170824 
 4019.00        X5000-START.                                                     <ATHB87> 170824 
 4020.00                                                                         <ATHB87> 170824 
 4021.00            INITIALIZE COVRAFI-PARAMS                                    <ATHB87> 170824 
 4022.00            INITIALIZE COVRAFIREC-KEY-DATA OF COVRAFI-PARAMS             <ATHB87> 170824 
 4023.00            INITIALIZE COVRAFIREC-NON-KEY-DATA                           <ATHB87> 170824 
 4024.00                                        OF COVRAFI-PARAMS                <ATHB87> 170824 
 4025.00                                                                         <ATHB87> 170824 
 4026.00            MOVE ZSCLABCK-CHDRCOY       TO COVRAFI-CHDRCOY               <ATHB87> 170824 
 4027.00            MOVE ZSCLABCK-CHDRNUM       TO COVRAFI-CHDRNUM               <ATHB87> 170824 
 4028.00            MOVE WSAA-ZCLB-COVERAGE     TO COVRAFI-COVERAGE              <ATHB87> 170824 
 4029.00            MOVE WSAA-ZCLB-RIDER        TO COVRAFI-RIDER                 <ATHB87> 170824 
 4030.00            MOVE WSAA-ZCLB-LIFE         TO COVRAFI-LIFE                  <ATHB87> 170824 
 4031.00            MOVE ZEROS                  TO COVRAFI-PLAN-SUFFIX           <ATHB87> 170824 
 4032.00                                                                         <ATHB87> 170824 
 4033.00            MOVE BEGN                   TO COVRAFI-FUNCTION              <ATHB87> 170824 
 4034.00            PERFORM X3650-COVRAFI-IO                                     <ATHB87> 170824 
 4035.00            IF  COVRAFI-STATUZ           = ENDP                          <ATHB87> 170824 
 4036.00                GO TO X5000-EXIT                                         <ATHB87> 170824 
 4037.00            END-IF                                                       <ATHB87> 170824 
 4038.00            MOVE COVRAFI-CRTABLE        TO WSAA-CRTABLE                  <ATHB87> 170824 
 4039.00                                                                         <ATHB87> 170824 
 4040.00            .                                                            <ATHB87> 170824 
 4041.00        X5000-EXIT.                                                      <ATHB87> 170824 
 4042.00            EXIT.                                                        <ATHB87> 170824 
 4043.00       /                                                                          151112 
 4044.00        XA25-CALL-ALOCNO  SECTION.                                                151112 
 4045.00       ***************************                                                151112 
 4046.00        XA25-START.                                                               151112 
 4047.00            INITIALIZE ALNO-ALOCNO-REC                                            151112 
 4048.00                                                                                  151112 
 4049.00            MOVE WSCC-CB                TO ALNO-PREFIX                            151116 
 4050.00            MOVE ZSCLABCK-CHDRCOY       TO ALNO-COMPANY                           151112 
 4051.00            MOVE ZSCLABCK-BATCTRCDE     TO ALNO-GENKEY                            151112 
 4052.00            IF  ZSCLABCK-FUNCTION        = WSCC-DECRP                    <ATHB37> 170215 
 4053.00                MOVE 'T512'             TO ALNO-GENKEY                   <ATHB37> 170215 
 4054.00            END-IF                                                       <ATHB37> 170215 
 4055.00            MOVE WSCC-NEXT              TO ALNO-FUNCTION                          151112 
 4056.00                                                                                  151112 
 4057.00            CALL 'ALOCNO'            USING ALNO-ALOCNO-REC                        151112 
 4058.00                                                                                  151112 
 4059.00            IF  ALNO-STATUZ          NOT = O-K                                    151112 
 4060.00                MOVE ALNO-ALOCNO-REC    TO SYSR-PARAMS                            151112 
 4061.00                MOVE ALNO-STATUZ        TO SYSR-STATUZ                            151112 
 4062.00                PERFORM 9000-FATAL-ERROR                                          151112 
 4063.00            END-IF                                                                151112 
 4064.00                                                                                  151112 
 4065.00            MOVE ALNO-ALOC-NO           TO WSAA-JPREMREG                          151112 
 4066.00            .                                                                     151112 
 4067.00        XA25-EXIT.                                                                151112 
 4068.00             EXIT.                                                                151112 
