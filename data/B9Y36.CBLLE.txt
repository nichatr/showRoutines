 0001.00        IDENTIFICATION DIVISION.                                             *    160407 
 0002.00        PROGRAM-ID. B9Y36.                                                   *    160407 
 0003.00       *                                                                     *    160407 
 0004.00       * Copyright 1986-2019, Computer Sciences Corporation.                      190402 
 0005.00       *                                                                     *    160407 
 0006.00       *REMARKS.                                                             *    160407 
 0007.00       *                                                                     *    160407 
 0008.00       *               Policy-Member-Notes for MEDNET                        *    160407 
 0009.00       *            (Orange Cross & Direct Multiple Life)                    *    160407 
 0010.00       *            *************************************                    *    161003 
 0011.00       *                                                                     *    160407 
 0012.00       * This program will extract the necessary policy information          *    160407 
 0013.00       * required by MEDNET on a daily basis. Two sets of extract files      *    160407 
 0014.00       * are always created:                                                 *    160407 
 0015.00       *                                                                     *    160407 
 0016.00       *  Mednet temporary extract details                                   *    160407 
 0017.00       *  ================================                                   *    160407 
 0018.00       *  - ZMDP (Policy Details)                                            *    160407 
 0019.00       *  - ZMDC (Member Coverage Details)                                   *    160407 
 0020.00       *  - ZMDN (Member Note Details)                                       *    160407 
 0021.00       *                                                                     *    160407 
 0022.00       *  ING Historical data                                                *    160407 
 0023.00       *  ===================                                                *    160407 
 0024.00       *  - ZNGP (Policy Details)                                            *    160407 
 0025.00       *  - ZNGC (Member Coverage Details)                                   *    160407 
 0026.00       *  - ZNGN (Member Note Details)                                       *    160407 
 0027.00       *                                                                     *    160407 
 0028.00       * Processing flow is as follows:                                      *    160411 
 0029.00       * ==============================                                      *    160407 
 0030.00       * 1 -Retrieve last MEDNET extr date from dataarea JRMDDATE2           *    160411 
 0031.00       *    and store in w/s field WSAA-DATAREA-DATE.                        *    160407 
 0032.00       *                                                                     *    160407 
 0033.00       * 2 -Retrieve last MEDNET extr seqno from dataarea ZMDSEQ72           *    160411 
 0034.00       *    and store in w/s field WSAA-SEQNUM.                              *    160407 
 0035.00       *                                                                     *    160407 
 0036.00       * 3 -Read thru ZPTREFC logical and select all recs where:             *    160411 
 0037.00       *    - trans code is in T5Z47                                         *    160407 
 0038.00       *    - trans date > dataarea date & <= batch run date                 *    160407 
 0039.00       *                                                                     *    160407 
 0040.00       * 4 -Get contract header details from CHDR & ZCHD files               *    160411 
 0041.00       *                                                                     *    160407 
 0042.00       * 5 -Get contract agent details from ZCHA & ZAGP files                *    160411 
 0043.00       *                                                                     *    160407 
 0044.00       * 6 -For each contract perform the following:                         *    160411 
 0045.00       *   a- Read T8Z65 and check if extra product rules apply.             *    160411 
 0046.00       *   b- Read T8Z91 and check if extra business rules apply.            *    160411 
 0047.00       *   c- If both T8Z65 & T8Z91 exist then we are processing a           *    160411 
 0048.00       *      direct sales contract. Check that the contract delivery        *    160407 
 0049.00       *      date is valid (ie not max date or zeroes).                     *    160407 
 0050.00       *   d- For direct sales contracts we only start sending extract       *    160411 
 0051.00       *      details to MEDNET when first payment has been made. This       *    160407 
 0052.00       *      will occur when we are processing the first B522 trans         *    160407 
 0053.00       *      (ie ZCHD-PTDATE = First Inst Date) and T8Z91 ind = Y.          *    160407 
 0054.00       *   e- If Contract Issue trans (T642) and contract has lapsed         *    160411 
 0055.00       *      in the meantime then we don't process PTRN.                    *    160407 
 0056.00       *                                                                     *    160407 
 0057.00       * 7 -Read thru all valid lives for the contract and store each        *    160411 
 0058.00       *    life client no in w/s table. A life is considered valid if       *    160407 
 0059.00       *    it has a coverage which exists in table T5Z48. For inforce       *    160407 
 0060.00       *    contracts the particular coverage must be inforce.               *    160407 
 0061.00       *    For all lives selected in the w/s table, we find the             *    160407 
 0062.00       *    principle life & life user code according to MEDNET rules.       *    160407 
 0063.00       *                                                                     *    160407 
 0064.00       * 8 -With the information gathered above we proceed to the            *    160411 
 0065.00       *    extraction processing which is as follows:                       *    160407 
 0066.00       *                                                                     *    160407 
 0067.00       * 9 -Extract Policy Details                                           *    160411 
 0068.00       * =========================                                           *    160411 
 0069.00       *   a- Read ZMDP for contract. If found, then bypass extraction       *    160411 
 0070.00       *      process as this has already taken place by a previous          *    160407 
 0071.00       *      PTRN transaction.                                              *    160407 
 0072.00       *   b- Read ZNGP for contract. If found, set rel ind to true          *    160411 
 0073.00       *      and store trans type. If the principal life has changed        *    160407 
 0074.00       *      then write out new ZMDP with tran type 10 (Cancellation)       *    160407 
 0075.00       *      in order to register that current main life is cancelled.      *    160407 
 0076.00       *   c- If ZNGP already exists then delete it.                         *    160411 
 0077.00       *   d- Write new ZMDP/ZNGP with principle life client details.        *    160411 
 0078.00       *      If princliple life has not changed then tran type will         *    160407 
 0079.00       *      be 30 (Correction) otherwise 01 (Initial).                     *    160407 
 0080.00       *                                                                     *    160407 
 0081.00       * 10-Extract Member & Note Details                                    *    160411 
 0082.00       * ================================                                    *    160411 
 0083.00       *   a- Read thru all ZNGC records for contract and store each         *    160411 
 0084.00       *      record a w/s table. For each record found we:                  *    160407 
 0085.00       *      - Check each ZNGC member against life w/s table.               *    160411 
 0086.00       *      - If member no longer exists and contract inforce then         *    160411 
 0087.00       *        write a new ZNGC record for the deleted member with          *    160407 
 0088.00       *        tran type 40 (Member Cancellation) in order to register      *    160407 
 0089.00       *        that the particular life is cancelled.                       *    160407 
 0090.00       *      - Delete current ZNGC record.                                  *    160425 
 0091.00       *                                                                     *    160407 
 0092.00       *   b- Read thru all ZNGN records for contract. For each rec:         *    160411 
 0093.00       *      - Delete current ZNGN record.                                  *    160411 
 0094.00       *                                                                     *    160407 
 0095.00       *   c- Read thru life w/s table. For each life we:                    *    160411 
 0096.00       *      - Check for valid coverage in T5Z48. If coverage found         *    160411 
 0097.00       *        we write out new ZMDC/ZNGC member detail records.            *    160411 
 0098.00       *      - check if coverage has particular clause text. If so          *    160411 
 0099.00       *        write out new ZMDN/ZNGN note details records.                *    160407 
 0100.00       *                                                                     *    160407 
 0101.00       * 11-Check for Changes to LIFE400 Client Details                      *    160411 
 0102.00       * ==============================================                      *    160411 
 0103.00       *   a- Read thru all CLTS via sql and select records where            *    160411 
 0104.00       *      the datime stamp is > dataarea & <= batch effdate.             *    160411 
 0105.00       *   b- For each client found, get the CCS no and read thru            *    160411 
 0106.00       *      ZNGCCLN logical and store all contract no's for the            *    160411 
 0107.00       *      client in a w/s table. For each contract no found in           *    160411 
 0108.00       *      the w/s table, we perform steps 7 to 10 mentioned above        *    160411 
 0109.00       *      in order to update the policy and member details.              *    160411 
 0110.00       *                                                                     *    160407 
 0111.00       * 12-Check for Changes to NELIS Client IBAN Details                   *    160411 
 0112.00       *  ================================================                   *    160411 
 0113.00       *   a- Read NELIS logical LPELCMP3 and select all recs where          *    160411 
 0114.00       *      last modify date is > dataarea date & <= batch effdate.        *    160411 
 0115.00       *   b- For each record found, get the CCS no and read thru            *    160411 
 0116.00       *      ZNGCCLN logical and store all contract no's for the            *    160411 
 0117.00       *      client in a w/s table. For each contract no found in           *    160411 
 0118.00       *      the w/s table, we perform steps 7 to 10 mentioned above        *    160411 
 0119.00       *      in order to update the policy and member details.              *    160411 
 0120.00       *                                                                     *    160407 
 0121.00       * 13-Update dataarea JMDDATE72 with BSSC-EFFECTIVE-DATE               *    160411 
 0122.00       *                                                                     *    160407 
 0123.00       * 14-Update dataarea ZMDSEQ72 with WSAA-SEQNUM (last used).           *    160411 
 0124.00       *                                                                     *    160407 
 0125.00       ***********************************************************************    950428 
 0126.00       *           AMENDMENT  HISTORY                                        *    160912 
 0127.00       ***********************************************************************    950428 
 0128.00       * DATE.... VSN/MOD  WORK UNIT    BY....                               *    950428 
 0129.00       *                                                                     *    950428 
 0130.00       * 07/04/16  01/01   ATHA68       Dimitri Lerantges                    *    160407 
 0131.00       *           Initial version.                                          *    160407 
 0132.00       *                                                                     *    160407 
 0133.00       * 13/09/16  01/01   ATHA68       Androni Katerina                     *    160913 
 0134.00       *           Proccess improvements                                     *    160913 
 0135.00       *                                                                     *    160913 
 0136.00       * 18/05/17  01/01   ATHB67       Androni Katerina                     *    170518 
 0137.00       *           RECOMPILE DUE TO CHANGES IN TABLE T8Z91                   *    170518 
 0138.00       *                                                                     *    170518 
 0139.00       * 20/07/17  01/01   ATHB72       Μποζιονέλος Σπύρος                   *    170720 
 0140.00       *           Recompile due to T8Z91 changes.                           *    170720 
 0141.00       *                                                                     *    170720 
 0142.00       * 21/09/17  01/01   ATHB86       Μποζιονέλος Σπύρος                   *    170921 
 0143.00       *           Recompile due to T8Z91 changes.                           *    170921 
 0144.00       *                                                                     *    170921 
 0145.00       * 07/03/18  01/01   ATHC40       Androni Katerina                     *    180307 
 0146.00       *           Changes due to change in table t7z37 .                    *    180307 
 0147.00       *           Increase IX-SPCAT-MAX from 15 to 30.                      *    180307 
 0148.00       *                                                                     *    180503 
 0149.00       * 03/05/18  01/01   ATH999       Androni Katerina                     *    180503 
 0150.00       *           Change datcon2 to datcon4. If the date was the last day   *    180503 
 0151.00       *           of the month datcon2 did not calculate the date correctlly*    180503 
 0152.00       *                                                                     *    180516 
 0153.00       * 16/05/18  01/01   ATHC58       Androni Katerina                     *    180516 
 0154.00       *           REPLACE T8Z91 WITH THE NEW T9Z69 - FIRST PAYMENT CHECK    *    180516 
 0155.00       *                                                                     *    180516 
 0156.00       * 01/06/18  01/01   ATHC60       Mitraina Eyaggelia                   *    180601 
 0157.00       *           IT3724 - Αλλαγή στην τιμή του αρ.επισκέψεων               *    180606 
 0158.00       *           Modify Table T5Z48 to be dated                            *    180601 
 0159.00       *                                                                     *    180613 
 0160.00       * 31/07/18  01/01   ATHC84       Mitraina Eyaggelia                   *    180731 
 0161.00       *           IT3738 - When HRP2 expires and HRP3 is activated,         *    180731 
 0162.00       *           only record HRP3 will be sent to MedNet.                       180731 
 0163.00       *                                                                     *    180731 
 0164.00       * 29/03/19  01/01   ATHD10       Zois George                          *    190329 
 0165.00       *           When adding a new member the effective date should be     *    190329 
 0166.00       *           the Risk Commence Date of the added member coverage       *    190329 
 0167.00       *           and not the contract Original Commencement Date.          *    190329 
 0168.00       *           Same applies to paid to date field ("Enrolment date"      *    190402 
 0169.00       *           as per Mednet terminology)                                *    190402 
 0170.00       *                                                                     *    190329 
 0171.00       **DD/MM/YY*************************************************************    190329 
 0172.00       *                                                                          000000 
 0173.00        ENVIRONMENT DIVISION.                                                     000000 
 0174.00        CONFIGURATION SECTION.                                                    160407 
 0175.00        SOURCE-COMPUTER.                                IBM-AS400.                160407 
 0176.00        OBJECT-COMPUTER.                                IBM-AS400.                160407 
 0177.00                                                                                  160407 
 0178.00        INPUT-OUTPUT SECTION.                                                     160407 
 0179.00        FILE-CONTROL.                                                             160407 
 0180.00       *                                                                          160411 
 0181.00            SELECT LPELCMP3 ASSIGN      TO DISK-LPELCMP3                          160411 
 0182.00                   ORGANIZATION         IS INDEXED                                160411 
 0183.00                   ACCESS MODE          IS SEQUENTIAL                             160411 
 0184.00                   RECORD KEY           IS LPELCMP3-KEY                           160411 
 0185.00                   FILE STATUS          IS LPELCMP3-STATUS.                       160411 
 0186.00       /                                                                          160407 
 0187.00        DATA DIVISION.                                                            160407 
 0188.00        FILE SECTION.                                                             160407 
 0189.00                                                                                  160407 
 0190.00        FD  LPELCMP3 LABEL RECORDS ARE STANDARD                                   160411 
 0191.00            DATA RECORD IS LPELCMP3R.                                             160411 
 0192.00                                                                                  160411 
 0193.00        01  LPELCMP3R                   PIC  X(121).                              160411 
 0194.00        02  RECORD-DESCRIPTION.                                                   160411 
 0195.00            03  P8CUS                   PIC  9(08).                               160411 
 0196.00            03  P8TYPI                  PIC  9(03).                               160411 
 0197.00            03  P8CODI                  PIC  9(02).                               160411 
 0198.00            03  P8TXT1                  PIC  X(35).                               160411 
 0199.00            03  P8TXT2                  PIC  X(35).                               160411 
 0200.00            03  P8ISX                   PIC  9(01).                               160411 
 0201.00            03  P8DSP                   PIC  9(01).                               160411 
 0202.00            03  P8USR                   PIC  X(10).                               160411 
 0203.00            03  P8DATY                  PIC  9(04).                               160411 
 0204.00            03  P8DATM                  PIC  9(02).                               160411 
 0205.00            03  P8DATD                  PIC  9(02).                               160411 
 0206.00            03  P8FLR1                  PIC  9(08).                               160411 
 0207.00            03  P8FLR2                  PIC  X(07).                               160411 
 0208.00            03  P8FLG1                  PIC  X(01).                               160411 
 0209.00            03  P8FLG2                  PIC  X(01).                               160411 
 0210.00            03  P8FLG3                  PIC  X(01).                               160411 
 0211.00                                                                                  160411 
 0212.00        66  LPELCMP3-KEY RENAMES P8DATY THRU P8DATD.                              160411 
 0213.00       /                                                                          160407 
 0214.00        WORKING-STORAGE SECTION.                                                  160407 
 0215.00       *                                                                          160407 
 0216.00        01  WSAA-PROG                   PIC X(05) VALUE 'B9Y36'.                  160427 
 0217.00        01  WSAA-VERSION                PIC X(02) VALUE '01'.                     160408 
 0218.00       *                                                                          160407 
 0219.00        77  LPELCMP3-STATUS             PIC X(02).                                160408 
 0220.00        77  FOUND3-REC                  PIC X(02)  VALUE '00'.                    160408 
 0221.00       *                                                                          160407 
 0222.00        01  WSAA-VARIABLES.                                                       160407 
 0223.00            03 IU                       PIC 9(02).                                160408 
 0224.00            03 IV                       PIC 9(02).                                160408 
 0225.00            03 IW                       PIC 9(02).                                160408 
 0226.00            03 IX                       PIC 9(02).                                160408 
 0227.00            03 IY                       PIC 9(02).                                160408 
 0228.00            03 IZ                       PIC 9(02).                                160408 
 0229.00            03 ZNGN-I                   PIC 9(02).                       <ATHC84> 180806 
 0230.00            03 WSAA-SUB                 PIC 9(02).                                160412 
 0231.00            03 WSAA-CHDRNUM-FROM        PIC X(08).                                160411 
 0232.00            03 WSAA-CHDRNUM-TO          PIC X(08).                                160411 
 0233.00            03 WSAA-WORK-CHDRCOY        PIC X(02).                                160407 
 0234.00            03 WSAA-WORK-CHDRNUM        PIC X(08).                                160407 
 0235.00            03 WSAA-WORK-EFFDATE        PIC 9(08).                                160407 
 0236.00            03 WSAA-REN-EFF-DATE        PIC 9(08).                                160914 
 0237.00            03 WSAA-WORK-CLNTNUM        PIC X(08).                                160407 
 0238.00            03 WSAA-WORK-ZLFCODE        PIC X(08).                                160408 
 0239.00            03 WSAA-WORK-CAT-SP         PIC X(02).                                160407 
 0240.00            03 WSAA-WORK-CCSNO          PIC X(08).                                160407 
 0241.00            03 WSAA-MAIN-LIFCNUM        PIC X(08).                                160407 
 0242.00            03 WSAA-MAIN-CCSNO          PIC X(08).                                160407 
 0243.00            03 WSAA-MAIN-CCSNOCL        PIC X(08).                                160407 
 0244.00            03 WSAA-CLEAN-CCSNO         PIC X(08).                                160407 
 0245.00            03 WSAA-WORK-LIFE           PIC X(02).                                160407 
 0246.00            03 WSAA-WORK-CRTABLE        PIC X(04).                                160407 
 0247.00            03 WSAA-WORK-CRCODE         PIC X(04).                                160407 
 0248.00            03 WSAA-WORK-ZTRNTYP        PIC X(02).                                160407 
 0249.00            03 WSAA-TRAN-TYP            PIC X(05).                                160916 
 0250.00            03 WSAA-ZNGP-ZTRNTYP        PIC X(02).                                160407 
 0251.00            03 WSAA-JCTX-ENTITY.                                                  160408 
 0252.00               05 WSAA-JCTX-CHDRNUM     PIC X(08).                                160408 
 0253.00               05 FILLER                PIC X(01)  VALUE '-'.                     160408 
 0254.00               05 WSAA-JCTX-LIFE        PIC X(02).                                160408 
 0255.00               05 WSAA-JCTX-COVERAGE    PIC X(02).                                160408 
 0256.00               05 WSAA-JCTX-RIDER       PIC X(02).                                160408 
 0257.00            03 WSAA-JCLT-ENTITY.                                                  160408 
 0258.00               05 WSAA-JCLT-CHDRNUM     PIC X(08).                                160408 
 0259.00               05 FILLER                PIC X(01)  VALUE '-'.                     160408 
 0260.00               05 WSAA-JCLT-LIFE        PIC X(02).                                160408 
 0261.00               05 WSAA-JCLT-COVERAGE    PIC X(02).                                160408 
 0262.00               05 WSAA-JCLT-RIDER       PIC X(02).                                160408 
 0263.00            03  WSAA-SEQNUM             PIC 9(15).                                160408 
 0264.00            03  WSAA-SQL-STAT           PIC X(04).                                160408 
 0265.00            03  WSAA-AGNTNUM.                                                     160407 
 0266.00                05 WSAA-AGNTNUM-3       PIC X(03).                                160408 
 0267.00                05 WSAA-AGNTNUM-5       PIC X(05).                                160408 
 0268.00            03  WSAA-AGENT.                                                       160407 
 0269.00                05 WSAA-AGENT-NUM       PIC X(03).                                160408 
 0270.00                05 WSAA-AGENT-ZEROES    PIC X(05) VALUE '00000'.                  160408 
 0271.00            03  WSAA-CLIENT-NAME.                                                 160407 
 0272.00                05 WSAA-CLIENT-SURNAME  PIC X(30).                                160408 
 0273.00                05 WSAA-CLIENT-GIVNAME  PIC X(20).                                160408 
 0274.00            03 WSAA-DESC-DATE           PIC X(15).                                160408 
 0275.00       **** 03 WSAA-T8Z91-ITEM.                                          <ATHC58> 180516 
 0276.00       ****     05 WSAA-T8Z91-SRCEBUS   PIC X(02).                       <ATHC58> 180516 
 0277.00       ****     05 WSAA-T8Z91-CNTTYPE   PIC X(03).                       <ATHC58> 180516 
 0278.00       ****     05 FILLER               PIC X(03).                       <ATHC58> 180516 
 0279.00            03 WSAA-T9Z69-ITEM.                                          <ATHC58> 180516 
 0280.00                05 WSAA-T9Z69-SRCEBUS   PIC X(02).                       <ATHC58> 180516 
 0281.00                05 WSAA-T9Z69-CNTTYPE   PIC X(03).                       <ATHC58> 180516 
 0282.00                05 FILLER               PIC X(03).                       <ATHC58> 180516 
 0283.00            03 WSAA-TOT-LIVES           PIC 9(02).                                160408 
 0284.00            03 WSAA-TOT-CONTRACTS       PIC 9(02).                                160408 
 0285.00            03 WSAA-RELATION-CODE       PIC X(02).                                160407 
 0286.00            03 WSAA-CATEGORY-KEY.                                                 160408 
 0287.00               05 WSAA-RCLASS           PIC X(02).                                160408 
 0288.00               05 WSAA-COINS            PIC X(02).                                160408 
 0289.00               05 WSAA-DEDUCT           PIC X(02).                                160408 
 0290.00            03 WSAA-TRANS-DATE          PIC 9(06).                                160408 
 0291.00            03 WSAA-FIRST-INST-DATE     PIC 9(08).                                160408 
 0292.00            03 WSAA-DATCON1-DATE        PIC S9(08).                               160412 
 0293.00            03 WSAA-USE-AGE-DATE        PIC  9(08).                      <ATHC60> 180601 
 0294.00            03 WSAA-DATCON2-FOR         PIC S9(03).                      <ATHC60> 180601 
 0295.00            03 WSAA-DATCON2-FREQ        PIC  X(02).                      <ATHC60> 180601 
 0296.00            03 WSAA-DATCON2-FROM-DATE   PIC  9(08).                      <ATHC60> 180601 
 0297.00            03 WSAA-DATCON2-DATE        PIC  9(08).                      <ATHC60> 180601 
 0298.00            03 WSAA-RERATE-FROM-DATE    PIC  9(08).                      <ATHC60> 180608 
 0299.00       *                                                                          160407 
 0300.00       * W/S Dates                                                                160408 
 0301.00       *                                                                          160407 
 0302.00        01  WSAA-DATAREA-DATE           PIC 9(08).                                160411 
 0303.00        01  WSAA-DATAREA-DATE-R REDEFINES WSAA-DATAREA-DATE.                      160411 
 0304.00            03  WSAA-DATAREA-YEAR       PIC 9(04).                                160411 
 0305.00            03  WSAA-DATAREA-MONTH      PIC 9(02).                                160411 
 0306.00            03  WSAA-DATAREA-DAY        PIC 9(02).                                160411 
 0307.00       *                                                                          160411 
 0308.00        01  WSAA-DATIME-DATE.                                                     160407 
 0309.00            03  WSAA-DATIME             PIC X(26).                                160408 
 0310.00            03  FILLER REDEFINES WSAA-DATIME.                                     160407 
 0311.00                05 WSAA-DATIME-YEAR     PIC 9(04).                                160408 
 0312.00                05 FILLER               PIC X(01).                                160408 
 0313.00                05 WSAA-DATIME-MONTH    PIC 9(02).                                160408 
 0314.00                05 FILLER               PIC X(01).                                160408 
 0315.00                05 WSAA-DATIME-DAY      PIC 9(02).                                160408 
 0316.00                05 FILLER               PIC X(16).                                160408 
 0317.00       *                                                                          160408 
 0318.00        01  WSAA-CONV-DATE.                                                       160408 
 0319.00            03  WSAA-CONV-YEAR20        PIC 9(02).                                160408 
 0320.00            03  WSAA-CONV-YEAR          PIC 9(02).                                160408 
 0321.00            03  WSAA-CONV-MONTH         PIC 9(02).                                160408 
 0322.00            03  WSAA-CONV-DAY           PIC 9(02).                                160408 
 0323.00       *                                                                          160408 
 0324.00        01  WSAA-BREAK-DATE.                                                      160408 
 0325.00            03  WSAA-BREAK-YEAR         PIC 9(02).                                160408 
 0326.00            03  WSAA-BREAK-MONTH        PIC 9(02).                                160408 
 0327.00            03  WSAA-BREAK-DAY          PIC 9(02).                                160408 
 0328.00       *                                                                          160408 
 0329.00        01  WSAA-TRANS-DATE-NEW.                                                  160408 
 0330.00            03  WSAA-TRANS-YEAR20       PIC 9(02).                                160408 
 0331.00            03  WSAA-TRANS-YEAR         PIC 9(02).                                160408 
 0332.00            03  WSAA-TRANS-MONTH        PIC 9(02).                                160408 
 0333.00            03  WSAA-TRANS-DAY          PIC 9(02).                                160408 
 0334.00       *                                                                          160408 
 0335.00       *01  WSAA-REN-EFF-DATE.                                                    160914 
 0336.00       **   03  WSAA-REN-EFF-YEAR20     PIC 9(02).                                160914 
 0337.00       **   03  WSAA-REN-EFF-YEAR       PIC 9(02).                                160914 
 0338.00       **   03  WSAA-REN-EFF-MONTH      PIC 9(02).                                160914 
 0339.00       **   03  WSAA-REN-EFF-DAY        PIC 9(02).                                160914 
 0340.00       *                                                                          160408 
 0341.00        01  WSAA-CLNT-DATE.                                                       160408 
 0342.00            03  WSAA-CLNT-YEAR          PIC 9(04).                                160408 
 0343.00            03  WSAA-CLNT-MONTH         PIC 9(02).                                160408 
 0344.00            03  WSAA-CLNT-DAY           PIC 9(02).                                160408 
 0345.00       *                                                                          160408 
 0346.00        01  WSAA-IBAN-EFFDATE.                                                    160408 
 0347.00            03 WSAA-IBAN-YEAR           PIC 9(04).                                160408 
 0348.00            03 WSAA-IBAN-MONTH          PIC 9(02).                                160408 
 0349.00            03 WSAA-IBAN-DAY            PIC 9(02).                                160408 
 0350.00       *                                                                 <ATH999> 180503 
 0351.00        01  WSAA-OCCDATE                PIC 9(08).                       <ATH999> 180503 
 0352.00        01  WSAA-OCCDATE-RED   REDEFINES WSAA-OCCDATE.                   <ATH999> 180503 
 0353.00            03  WSAA-OCCYEAR            PIC 9(04).                       <ATH999> 180503 
 0354.00            03  WSAA-OCCMON             PIC 9(02).                       <ATH999> 180503 
 0355.00            03  WSAA-OCCDAY             PIC 9(02).                       <ATH999> 180503 
 0356.00       *                                                                          160407 
 0357.00       * W/S Sequence no                                                          160408 
 0358.00       *                                                                          160408 
 0359.00        01  WSAA-SEQUENCE.                                                        160407 
 0360.00            03  WSAA-SEQ-NUMBERS.                                                 160407 
 0361.00                05  WSAA-SEQ-NUMBER     PIC  X(1)                                 160407 
 0362.00                                     OCCURS 15 TIMES.                             160407 
 0363.00            03  WSAA-SEQ-NUMB REDEFINES WSAA-SEQ-NUMBERS.                         160407 
 0364.00                05  WSAA-NOFSEQ01       PIC X(01).                                160407 
 0365.00                05  WSAA-NOFSEQ02       PIC X(01).                                160407 
 0366.00                05  WSAA-NOFSEQ03       PIC X(01).                                160407 
 0367.00                05  WSAA-NOFSEQ04       PIC X(01).                                160407 
 0368.00                05  WSAA-NOFSEQ05       PIC X(01).                                160407 
 0369.00                05  WSAA-NOFSEQ06       PIC X(01).                                160407 
 0370.00                05  WSAA-NOFSEQ07       PIC X(01).                                160407 
 0371.00                05  WSAA-NOFSEQ08       PIC X(01).                                160407 
 0372.00                05  WSAA-NOFSEQ09       PIC X(01).                                160407 
 0373.00                05  WSAA-NOFSEQ010      PIC X(01).                                160407 
 0374.00                05  WSAA-NOFSEQ011      PIC X(01).                                160407 
 0375.00                05  WSAA-NOFSEQ012      PIC X(01).                                160407 
 0376.00                05  WSAA-NOFSEQ013      PIC X(01).                                160407 
 0377.00                05  WSAA-NOFSEQ014      PIC X(01).                                160407 
 0378.00                05  WSAA-NOFSEQ015      PIC X(01).                                160407 
 0379.00       *                                                                          160407 
 0380.00       * W/S Zero Replace                                                         160408 
 0381.00       *                                                                          160408 
 0382.00        01  WSAA-REPLACE-ZEROES.                                                  160407 
 0383.00            03  WSAA-REP-ZEROES.                                                  160407 
 0384.00                05  WSAA-REP-ZERO       PIC  X(1)                                 160407 
 0385.00                                     OCCURS 08 TIMES.                             160407 
 0386.00       *                                                                          160407 
 0387.00       * Arrays                                                                   160408 
 0388.00       *                                                                          160408 
 0389.00        01 WSAA-CHDRNUM-ARRAY.                                                    160408 
 0390.00           03 WSAA-CHDRNUM-RECORD  OCCURS 20.                                     160408 
 0391.00               05 WSAA-CHDRNUM          PIC X(08).                                160408 
 0392.00       *                                                                          160408 
 0393.00        01 WSAA-LIFCNUM-ARRAY.                                                    160408 
 0394.00           03 WSAA-LIFCNUM-RECORD  OCCURS 10.                                     160408 
 0395.00              05 WSAA-LIFCNUM           PIC X(08).                                160408 
 0396.00              05 WSAA-LIFCNUM-CCSNO     PIC X(08).                                160408 
 0397.00              05 WSAA-LIFCNUM-CCSNOCL   PIC X(08).                                160408 
 0398.00              05 WSAA-LIFCNUM-LIFE      PIC X(02).                                160408 
 0399.00              05 WSAA-LIFCNUM-JLIFE     PIC X(02).                                160408 
 0400.00              05 WSAA-LIFCNUM-REL       PIC X(02).                                160408 
 0401.00              05 WSAA-LIFCNUM-USERX     PIC X(01).                                160408 
 0402.00              05 WSAA-LIFCNUM-PRODN     PIC X(01).                                160408 
 0403.00       *                                                                          160408 
 0404.00        01 WSAA-ZNGC-ARRAY.                                                       160408 
 0405.00           03 WSAA-ZNGC-RECORD     OCCURS 10.                                     160408 
 0406.00              05 WSAA-ZNGC-ZLFCODE      PIC X(08).                                160408 
 0407.00              05 WSAA-ZNGC-JREGNO       PIC X(08).                                160408 
 0408.00       *                                                                 <ATHC84> 180806 
 0409.00        01 WSAA-ZNGN-ARRAY.                                              <ATHC84> 180806 
 0410.00           03 WSAA-ZNGN-RECORD                                           <ATHC84> 180806 
 0411.00                   OCCURS 10 TIMES                                       <ATHC84> 180806 
 0412.00       ****        ASCENDING WSAA-ZNGN-ZPOLICY, WSAA-ZNGN-ZLFCODE        <ATHC84> 180806 
 0413.00                   INDEXED BY INDX-1.                                    <ATHC84> 180806 
 0414.00              05 WSAA-ZNGN-ZPOLICY      PIC X(15).                       <ATHC84> 180806 
 0415.00              05 WSAA-ZNGN-ZLFCODE      PIC X(15).                       <ATHC84> 180806 
 0416.00       *                                                                          160408 
 0417.00        01  WSAA-INDEXES.                                                         160407 
 0418.00            03 IX-TABLE                 PIC 9(04).                                160408 
 0419.00            03 IY-TABLE                 PIC 9(04).                                160408 
 0420.00            03 WSAA-IND1                PIC 9(01).                                160408 
 0421.00            03 WSAA-IY                  PIC 9(04).                                160408 
 0422.00            03 IX-T7Z38-MAX             PIC 9(02) VALUE 20.                       160408 
 0423.00            03 IX-SPCAT                 PIC 9(02).                                160408 
 0424.00       **** 03 IX-SPCAT-MAX             PIC 9(02) VALUE 15.              <ATHC40> 180307 
 0425.00            03 IX-SPCAT-MAX             PIC 9(02) VALUE 30.              <ATHC40> 180307 
 0426.00            03 IX-T7Z38                 PIC 9(02).                                160408 
 0427.00       *                                                                          160407 
 0428.00       * Flags                                                                    160407 
 0429.00       *                                                                          160407 
 0430.00        01  WSAA-PROCESSING-FLAG        PIC X(01).                                160408 
 0431.00            88 PTRN-PROCESS-ACTIVE      VALUE 'P'.                                160408 
 0432.00            88 CLNT-PROCESS-ACTIVE      VALUE 'C'.                                160408 
 0433.00            88 IBAN-PROCESS-ACTIVE      VALUE 'I'.                                160408 
 0434.00        01  WSAA-RECORD-FLAG            PIC X(01).                                160408 
 0435.00            88 DONT-PROCESS-RECORD      VALUE 'N'.                                160408 
 0436.00            88 PROCESS-RECORD           VALUE 'Y'.                                160408 
 0437.00        01  WSAA-COVERAGE-LEVEL-FLAG    PIC X(01).                                160407 
 0438.00            88 NOT-COVERAGE-LEVEL       VALUE 'N'.                                160407 
 0439.00            88 COVERAGE-LEVEL           VALUE 'Y'.                                160407 
 0440.00        01  WSAA-RELATION-FLAG          PIC X(01).                                160407 
 0441.00            88 RELATION-NOT-FOUND       VALUE 'N'.                                160407 
 0442.00            88 RELATION-FOUND           VALUE 'Y'.                                160407 
 0443.00        01  WSAA-MAIN-LIFE-FLAG         PIC X(01).                                160407 
 0444.00            88 MAIN-LIFE-NOT-FOUND      VALUE 'N'.                                160407 
 0445.00            88 MAIN-LIFE-FOUND          VALUE 'Y'.                                160407 
 0446.00        01  WSAA-MEMBER-FLAG            PIC X(01).                                160407 
 0447.00            88 MEMBER-NOT-FOUND         VALUE 'N'.                                160407 
 0448.00            88 MEMBER-FOUND             VALUE 'Y'.                                160407 
 0449.00        01  WSAA-COVERAGE-FLAG          PIC X(01).                                160407 
 0450.00            88 COVERAGE-NOT-FOUND       VALUE 'N'.                                160407 
 0451.00            88 COVERAGE-FOUND           VALUE 'Y'.                                160407 
 0452.00        01  WSAA-T8Z65-FLAG             PIC X(01).                                160407 
 0453.00            88 T8Z65-NOT-FOUND          VALUE 'N'.                                160407 
 0454.00            88 T8Z65-FOUND              VALUE 'Y'.                                160407 
 0455.00      **01  WSAA-T8Z91-FLAG             PIC X(01).                       <ATHC58> 180516 
 0456.00      **    88 T8Z91-NOT-FOUND          VALUE 'N'.                       <ATHC58> 180516 
 0457.00      **    88 T8Z91-FOUND              VALUE 'Y'.                       <ATHC58> 180516 
 0458.00        01  WSAA-T9Z69-FLAG             PIC X(01).                       <ATHC58> 180516 
 0459.00            88 T9Z69-NOT-FOUND          VALUE 'N'.                       <ATHC58> 180516 
 0460.00            88 T9Z69-FOUND              VALUE 'Y'.                       <ATHC58> 180516 
 0461.00        01  WSAA-ZNGP-FLAG              PIC X(01).                                160407 
 0462.00            88 ZNGP-NOT-FOUND           VALUE 'N'.                                160407 
 0463.00            88 ZNGP-FOUND               VALUE 'Y'.                                160407 
 0464.00        01  WSAA-ZNGC-FLAG              PIC X(01).                                160407 
 0465.00            88 ZNGC-NOT-FOUND           VALUE 'N'.                                160407 
 0466.00            88 ZNGC-FOUND               VALUE 'Y'.                                160407 
 0467.00        01  WSAA-VALID-SP-COVR          PIC X(01).                                160407 
 0468.00            88 INVALID-SP-COVR          VALUE 'N'.                                160407 
 0469.00            88 VALID-SP-COVR            VALUE 'Y'.                                160407 
 0470.00        01  WSAA-CLAUSE-FLAG            PIC X(01).                                160407 
 0471.00            88 CLAUSE-NOT-FOUND         VALUE 'N'.                                160407 
 0472.00            88 CLAUSE-FOUND             VALUE 'Y'.                                160407 
 0473.00        01  WSAA-CONTRACT-FLAG          PIC X(01).                                160408 
 0474.00            88 CONTRACT-NOT-FOUND       VALUE 'N'.                                160408 
 0475.00            88 CONTRACT-FOUND           VALUE 'Y'.                                160408 
 0476.00        01  WSAA-CC-ROLE-FLAG           PIC X(01).                                160427 
 0477.00            88 CC-ROLE-NOT-FOUND        VALUE 'N'.                                160427 
 0478.00            88 CC-ROLE-FOUND            VALUE 'Y'.                                160427 
 0479.00       *                                                                          160408 
 0480.00       * Constants                                                                160408 
 0481.00       *                                                                          160408 
 0482.00        01  WSCC-CONSTANTS.                                                       160408 
 0483.00            03 WSCC-Y                   PIC X(01) VALUE 'Y'.                      160408 
 0484.00            03 WSCC-U                   PIC X(01) VALUE 'U'.                      160408 
 0485.00            03 WSCC-N                   PIC X(01) VALUE 'N'.                      160408 
 0486.00            03 WSCC-SYS-COY             PIC X(01) VALUE '0'.                      160408 
 0487.00            03 WSCC-1                   PIC 9(01) VALUE  1.                       160408 
 0488.00            03 WSCC-2                   PIC 9(01) VALUE  2.                       160408 
 0489.00            03 WSCC-3                   PIC 9(01) VALUE  3.                       160408 
 0490.00            03 WSCC-4                   PIC 9(01) VALUE  4.                       160408 
 0491.00            03 WSCC-5                   PIC 9(01) VALUE  5.                       160408 
 0492.00            03 WSCC-8                   PIC 9(01) VALUE  8.                       160408 
 0493.00            03 WSCC-001                 PIC X(03) VALUE  '001'.                   160408 
 0494.00            03 WSCC-72                  PIC X(02) VALUE '72'.                     160408 
 0495.00            03 WSCC-ZERO                PIC X(01) VALUE '0'.                      160408 
 0496.00            03 WSCC-3-ZEROES            PIC X(03) VALUE '000'.                    160408 
 0497.00            03 WSCC-10-ZEROES           PIC X(10) VALUE '0000000000'.             160408 
 0498.00            03 WSCC-10-NINES            PIC X(10) VALUE '9999999999'.             160408 
 0499.00            03 WSCC-00                  PIC X(02) VALUE '00'.                     160408 
 0500.00            03 WSCC-01                  PIC X(02) VALUE '01'.                     160408 
 0501.00            03 WSCC-02                  PIC X(02) VALUE '02'.                     160408 
 0502.00            03 WSCC-10                  PIC X(02) VALUE '10'.                     160408 
 0503.00            03 WSCC-20                  PIC X(02) VALUE '20'.                     160408 
 0504.00            03 WSCC-YEAR20              PIC 9(02) VALUE  20.                      160408 
 0505.00            03 WSCC-40                  PIC X(02) VALUE '40'.                     160408 
 0506.00            03 WSCC-41                  PIC X(02) VALUE '41'.                     160408 
 0507.00            03 WSCC-42                  PIC X(02) VALUE '42'.                     160408 
 0508.00            03 WSCC-30                  PIC X(02) VALUE '30'.                     160408 
 0509.00            03 WSCC-43                  PIC X(02) VALUE '43'.                     160408 
 0510.00            03 WSCC-COVERAGE-72.                                                  160408 
 0511.00               05 WSCC-72-COMPANY       PIC X(02) VALUE '72'.                     160408 
 0512.00               05 WSCC-CRTABLE-72       PIC X(04).                                160408 
 0513.00            03 WSCC-COVERAGE-T6Z33.                                               160408 
 0514.00               05 WSCC-CRTABLE-T6Z33    PIC X(04).                                160408 
 0515.00               05 WSCC-T6Z33-CAT-SP     PIC X(02).                                160408 
 0516.00            03 WSCC-CC                  PIC X(02) VALUE 'CC'.                     160408 
 0517.00            03 WSCC-CN                  PIC X(02) VALUE 'CN'.                     160408 
 0518.00            03 WSCC-CM                  PIC X(02) VALUE 'CM'.                     160408 
 0519.00            03 WSCC-I                   PIC X(01) VALUE 'I'.                      160408 
 0520.00            03 WSCC-GR                  PIC X(02) VALUE 'GR'.                     160408 
 0521.00            03 WSCC-IF                  PIC X(02) VALUE 'IF'.                     160408 
 0522.00            03 WSCC-DH                  PIC X(02) VALUE 'DH'.                     160927 
 0523.00            03 WSCC-STC6131             PIC X(07) VALUE 'STC6131'.                160408 
 0524.00            03 WSCC-STC6132             PIC X(07) VALUE 'STC6132'.                160408 
 0525.00            03 WSCC-STC6134             PIC X(07) VALUE 'STC6134'.                160408 
 0526.00            03 WSCC-MAX-REL             PIC 9(02) VALUE 5.                        160408 
 0527.00            03 WSCC-MAX-CNT1            PIC 9(02) VALUE 8.                        160408 
 0528.00            03 WSCC-MAX-T6Z33           PIC 9(02) VALUE 6.                        160408 
 0529.00            03 WSCC-MAX-CONTRACTS       PIC 9(02) VALUE 20.                       160408 
 0530.00            03 WSCC-MAX-LIVES           PIC 9(02) VALUE 10.                       160408 
 0531.00            03 WSCC-MODIF               PIC X(05) VALUE 'MODIF'.                  160916 
 0532.00            03 WSCC-CANCL               PIC X(05) VALUE 'CANCL'.                  160916 
 0533.00            03 WSCC-REACT               PIC X(05) VALUE 'REACT'.                  160916 
 0534.00            03 WSCC-NEW                 PIC X(03) VALUE 'NEW'.                    160916 
 0535.00            03 WSCC-ADD                 PIC X(03) VALUE 'ADD'.                    160916 
 0536.00            03 WSCC-CFI-TEXT            PIC X(58) VALUE                           160412 
 0537.00            'Το συμβολαιο ειναι απο υπαναχωρηση ακυρωση απο την εναρξη'.          160412 
 0538.00            03 WSCC-NUM--1              PIC S9(01) VALUE -1.             <ATHC60> 180601 
 0539.00            03 WSCC-TEXT-REMOVE-TERMS   PIC  X(40) VALUE                 <ATHC84> 180801 
 0540.00            'Εχουν αφαιρεθεί οι όροι από το συμβόλαιο'.                  <ATHC84> 180801 
 0541.00       *                                                                          160407 
 0542.00       * 88 Level                                                                 160407 
 0543.00       *                                                                          160407 
 0544.00        01  WS88-CONTROL-FLAGS.                                                   160407 
 0545.00            03  WS88-MUST-EXIT-LOOP     PIC X(01).                                160408 
 0546.00                88  MUST-EXIT-LOOP      VALUE 'Y'.                                160407 
 0547.00                88  NOT-MUST-EXIT-LOOP  VALUE 'N'.                                160407 
 0548.00            03  WSAA-VALID-ZNGCCLN      PIC  X(01).                               160407 
 0549.00              88 FOUND-ZNGCCLN          VALUE 'Y'.                                160407 
 0550.00              88 NOT-FOUND-ZNGCCLN      VALUE 'N'.                                160407 
 0551.00            03  WSAA-VALID-LIFEARC      PIC  X(01).                               160407 
 0552.00              88 FOUND-LIFEARC          VALUE 'Y'.                                160407 
 0553.00              88 NOT-FOUND-LIFEARC      VALUE 'N'.                                160407 
 0554.00            03  WSAA-FOUND-ZNGN         PIC  X(01).                      <ATHC84> 180801 
 0555.00              88 FOUND-ZNGN             VALUE 'Y'.                       <ATHC84> 180801 
 0556.00              88 NOT-FOUND-ZNGN         VALUE 'N'.                       <ATHC84> 180801 
 0557.00            03  WS88-STATCODE           PIC  X(02).                               160407 
 0558.00              88 CONTRACT-INFORCE       VALUE 'IF'.                               160407 
 0559.00              88 CONTRACT-CFI           VALUE 'CF'.                               160407 
 0560.00              88 CONTRACT-LAPSED        VALUE 'LA'.                               160407 
 0561.00              88 CONTRACT-PAIDUP        VALUE 'PU'.                               160411 
 0562.00              88 CONTRACT-SURRENDERED   VALUE 'SU'.                               160411 
 0563.00              88 CONTRACT-RD            VALUE 'RD'.                               160927 
 0564.00              88 CONTRACT-DH            VALUE 'DH'.                               160927 
 0565.00            03  WS88-BATCTRCDE          PIC  X(04).                               160407 
 0566.00              88 TRAN-COLLECTION        VALUE 'B522'.                             160407 
 0567.00              88 TRAN-RENEWAL           VALUE 'B672'.                             160407 
 0568.00              88 TRAN-SPECIAL           VALUE 'T514',                             160407 
 0569.00                                              'T557'.                             160407 
 0570.00              88 TRAN-ISSUE             VALUE 'T642'.                             160407 
 0571.00       *                                                                          160407 
 0572.00       * These fields are required by MAINB processing and should not             160407 
 0573.00       *   be deleted.                                                            160407 
 0574.00       *                                                                          160407 
 0575.00        01  WSAA-COMMIT-CNT             PIC S9(08) COMP-3.                        160407 
 0576.00        01  WSAA-CYCLE-CNT              PIC S9(08) COMP-3.                        160407 
 0577.00        01  WSAA-CNT                    PIC  9(02).                               160407 
 0578.00        01  WSSP-EDTERROR               PIC  X(04).                               160407 
 0579.00       *                                                                          160407 
 0580.00       *****************************************************************          160407 
 0581.00       *    C O N T R O L   T O T A L S                                           160407 
 0582.00       *****************************************************************          160407 
 0583.00       *                                                                          160407 
 0584.00       * CT01 - Total ZMDP records written                                        160408 
 0585.00       * CT02 - Total ZMDC records written                                        160408 
 0586.00       * CT03 - Total ZMDN records written                                        160408 
 0587.00       * CT04 - Total ZMDP initial records written                                160408 
 0588.00       * CT05 - Total ZMDP modify records written                                 160408 
 0589.00       * CT06 - Total ZMDP cancel records written                                 160408 
 0590.00       * CT07 - Total ZMDC initial records written                                160408 
 0591.00       * CT08 - Total ZMDC modify records written                                 160408 
 0592.00       * CT09 - Total ZMDC cancel records written                                 160408 
 0593.00       * CT10 - Total ZMDC member addition records written                        160408 
 0594.00       * CT11 - Total CLNT records read                                           160408 
 0595.00       * CT12 - Total CLNT records selected                                       160412 
 0596.00       * CT13 - Total CLNT change contracts selected                              160412 
 0597.00       * CT14 - Total IBAN records read                                           160412 
 0598.00       * CT15 - Total IBAN records selected                                       160412 
 0599.00       * CT16 - Total IBAN change contracts selected                              160412 
 0600.00       *                                                                          160408 
 0601.00        01  CONTROL-TOTALS.                                                       160407 
 0602.00            03  CT01                    PIC 9(02) VALUE 01.                       160407 
 0603.00            03  CT02                    PIC 9(02) VALUE 02.                       160407 
 0604.00            03  CT03                    PIC 9(02) VALUE 03.                       160407 
 0605.00            03  CT04                    PIC 9(02) VALUE 04.                       160407 
 0606.00            03  CT05                    PIC 9(02) VALUE 05.                       160407 
 0607.00            03  CT06                    PIC 9(02) VALUE 06.                       160407 
 0608.00            03  CT07                    PIC 9(02) VALUE 07.                       160407 
 0609.00            03  CT08                    PIC 9(02) VALUE 08.                       160407 
 0610.00            03  CT09                    PIC 9(02) VALUE 09.                       160407 
 0611.00            03  CT10                    PIC 9(02) VALUE 10.                       160408 
 0612.00            03  CT11                    PIC 9(02) VALUE 11.                       160408 
 0613.00            03  CT12                    PIC 9(02) VALUE 12.                       160408 
 0614.00            03  CT13                    PIC 9(02) VALUE 13.                       160408 
 0615.00            03  CT14                    PIC 9(02) VALUE 14.                       160408 
 0616.00            03  CT15                    PIC 9(02) VALUE 15.                       160412 
 0617.00            03  CT16                    PIC 9(02) VALUE 16.                       160412 
 0618.00       *                                                                          160407 
 0619.00       *****************************************************************          160407 
 0620.00       *    F O R M A T S                                                         160407 
 0621.00       *****************************************************************          160407 
 0622.00       *                                                                          160407 
 0623.00       * The formats BUPA BSSC BPRD BSPR and BMSG are required by MAINB           160407 
 0624.00       * processing and should not be deleted.                                    160407 
 0625.00       *                                                                          160407 
 0626.00        01  FORMATS.                                                              160407 
 0627.00            03  BMSGREC                 PIC X(10) VALUE 'BMSGREC'.                160408 
 0628.00            03  BPRDREC                 PIC X(10) VALUE 'BPRDREC'.                160408 
 0629.00            03  BSPRREC                 PIC X(10) VALUE 'BSPRREC'.                160408 
 0630.00            03  BSSCREC                 PIC X(10) VALUE 'BSSCREC'.                160408 
 0631.00            03  BUPAREC                 PIC X(10) VALUE 'BUPAREC'.                160408 
 0632.00            03  DESCREC                 PIC X(10) VALUE 'DESCREC'.                160408 
 0633.00            03  CLNTREC                 PIC X(10) VALUE 'CLNTREC'.                160408 
 0634.00            03  CLRRWINREC              PIC X(10) VALUE 'CLRRWINREC'.             160408 
 0635.00            03  CHDRINPREC              PIC X(10) VALUE 'CHDRINPREC'.             160408 
 0636.00            03  COVRREC                 PIC X(10) VALUE 'COVRREC'.                160408 
 0637.00            03  COVRENQREC              PIC X(10) VALUE 'COVRENQREC'.             160408 
 0638.00            03  ITDMREC                 PIC X(10) VALUE 'ITEMREC'.                160408 
 0639.00            03  ITEMREC                 PIC X(10) VALUE 'ITEMREC'.                160408 
 0640.00            03  JCTXREC                 PIC X(10) VALUE 'JCTXREC'.                160408 
 0641.00            03  JCLTREC                 PIC X(10) VALUE 'JCLTREC'.                160408 
 0642.00            03  LEXTREC                 PIC X(10) VALUE 'LEXTREC'.                160408 
 0643.00            03  LIFEARCREC              PIC X(10) VALUE 'LIFEARCREC'.             160408 
 0644.00            03  ZAGPCTOREC              PIC X(10) VALUE 'ZAGPCTOREC'.             160408 
 0645.00            03  ZCHAFLGREC              PIC X(10) VALUE 'ZCHAFLGREC'.             160408 
 0646.00            03  ZCHDREC                 PIC X(10) VALUE 'ZCHDREC'.                160408 
 0647.00            03  ZMDCREC                 PIC X(10) VALUE 'ZMDCREC'.                160408 
 0648.00            03  ZMDNREC                 PIC X(10) VALUE 'ZMDNREC'.                160408 
 0649.00            03  ZMDPREC                 PIC X(10) VALUE 'ZMDPREC'.                160408 
 0650.00            03  ZNGCREC                 PIC X(10) VALUE 'ZNGCREC'.                160408 
 0651.00            03  ZNGCCLNREC              PIC X(10) VALUE 'ZNGCCLNREC'.             160408 
 0652.00            03  ZNGNREC                 PIC X(10) VALUE 'ZNGNREC'.                160408 
 0653.00            03  ZNGPREC                 PIC X(10) VALUE 'ZNGPREC'.                160408 
 0654.00            03  ZNGPCLNREC              PIC X(10) VALUE 'ZNGPCLNREC'.             160408 
 0655.00            03  ZPTREFCREC              PIC X(10) VALUE 'ZPTREFCREC'.             160408 
 0656.00       *                                                                          160407 
 0657.00       *****************************************************************          160407 
 0658.00       *    T A B L E S                                                           160407 
 0659.00       *****************************************************************          160407 
 0660.00       *                                                                          160407 
 0661.00        01  TABLES.                                                               160407 
 0662.00            03  T5Z44                   PIC X(05) VALUE 'T5Z44'.                  160407 
 0663.00            03  T5Z47                   PIC X(05) VALUE 'T5Z47'.                  160407 
 0664.00            03  T5Z48                   PIC X(05) VALUE 'T5Z48'.                  160407 
 0665.00            03  T6Z03                   PIC X(05) VALUE 'T6Z03'.                  160407 
 0666.00            03  T6Z33                   PIC X(05) VALUE 'T6Z33'.                  160407 
 0667.00            03  T7Z37                   PIC X(05) VALUE 'T7Z37'.                  160407 
 0668.00            03  T7Z38                   PIC X(05) VALUE 'T7Z38'.                  160407 
 0669.00            03  T8Z65                   PIC X(05) VALUE 'T8Z65'.                  160407 
 0670.00       ***  03  T8Z91                   PIC X(05) VALUE 'T8Z91'.         <ATHC58> 180516 
 0671.00            03  T9Z20                   PIC X(05) VALUE 'T9Z20'.                  160916 
 0672.00            03  T9Z69                   PIC X(05) VALUE 'T9Z69'.         <ATHC58> 180516 
 0673.00       *                                                                          160407 
 0674.00       *****************************************************************          160407 
 0675.00       *    S Q L                                                                 160407 
 0676.00       *****************************************************************          160407 
 0677.00       *                                                                          160407 
 0678.00       * SQL control data structure                                               160407 
 0679.00       *                                                                          160407 
 0680.00            EXEC SQL                                                              160407 
 0681.00               INCLUDE SQLCA                                                      160407 
 0682.00            END-EXEC.                                                             160407 
 0683.00                                                                                  160407 
 0684.00        01  FILLER.                                                               160407 
 0685.00            03  SQL-ERROR-CODE          PIC S9(09).                               160407 
 0686.00            03  FILLER REDEFINES SQL-ERROR-CODE.                                  160407 
 0687.00                05  FILLER              PIC X(05).                                160407 
 0688.00                05  SQL-STATUZ          PIC X(04).                                160407 
 0689.00       *                                                                          160407 
 0690.00       * Define files accessed using SQL to SMART                                 160407 
 0691.00       * Define the fields required by SQL                                        160407 
 0692.00       *                                                                          160407 
 0693.00        01  SQL-CLNTPF.                                                           160407 
 0694.00            05  CLNTREC1.                                                         160407 
 0695.00                10  SQL-CLNTPFX         PIC X(02).                                160407 
 0696.00                10  SQL-CLNTCOY         PIC X(01).                                160407 
 0697.00                10  SQL-CLNTNUM         PIC X(08).                                160407 
 0698.00                10  SQL-DATIME          PIC X(26).                                160407 
 0699.00       *                                                                          160408 
 0700.00       *  Control indicators                                                      160408 
 0701.00       *                                                                          160408 
 0702.00        77  WSAA-OVERFLOW-A             PIC X(01) VALUE 'Y'.                      160408 
 0703.00        88  NEW-PAGE-REQ-A                        VALUE 'Y'.                      160408 
 0704.00       *                                                                          160408 
 0705.00        77  WSAA-OVERFLOW-B             PIC X(01) VALUE 'Y'.                      160408 
 0706.00        88  NEW-PAGE-REQ-B                        VALUE 'Y'.                      160408 
 0707.00       *                                                                          160408 
 0708.00        77  WSAA-OVERFLOW-C             PIC X(01) VALUE 'Y'.                      160408 
 0709.00        88  NEW-PAGE-REQ-C                        VALUE 'Y'.                      160408 
 0710.00       *                                                                          160408 
 0711.00        77  WSAA-EOF                    PIC X(01) VALUE 'N'.                      160408 
 0712.00        88  END-OF-FILE                           VALUE 'Y'.                      160408 
 0713.00       *                                                                          160408 
 0714.00        01  INDIC-AREA.                                                           160408 
 0715.00            03  INDIC-TABLE  OCCURS 99  PIC 1 INDICATOR 1.                        160408 
 0716.00                88  IND-OFF  VALUE B'0'.                                          160408 
 0717.00                88  IND-ON   VALUE B'1'.                                          160408 
 0718.00       *                                                                          160407 
 0719.00       *****************************************************************          160407 
 0720.00       *    C O P Y N O O K S                                                     160407 
 0721.00       *****************************************************************          160407 
 0722.00       *                                                                          160407 
 0723.00       * Batch copybooks                                                          160407 
 0724.00       *                                                                          160407 
 0725.00            COPY BATCDORREC.                                                      160407 
 0726.00            COPY BATCUPREC.                                                       160407 
 0727.00            COPY BSSCSKM.                                                         160407 
 0728.00            COPY BSPRSKM.                                                         160407 
 0729.00            COPY BUPASKM.                                                         160407 
 0730.00            COPY BPRDSKM.                                                         160407 
 0731.00       *                                                                          160407 
 0732.00       * System copybooks                                                         160407 
 0733.00       *                                                                          160407 
 0734.00            COPY CONLOGREC.                                                       160407 
 0735.00            COPY CONTOTREC.                                                       160407 
 0736.00            COPY FREQCPY.                                                         160407 
 0737.00            COPY FSUPFXCPY.                                                       160407 
 0738.00            COPY SFTLOCKREC.                                                      160407 
 0739.00            COPY SMTPFXCPY.                                                       160407 
 0740.00            COPY SYSERRREC.                                                       160407 
 0741.00            COPY VARCOM.                                                          160407 
 0742.00            COPY LSTATUSCPY.                                             <ATHC84> 180801 
 0743.00       *                                                                          160407 
 0744.00       * Database schemas                                                         160407 
 0745.00       *                                                                          160411 
 0746.00            COPY COVRSKM.                                                         160407 
 0747.00        01  WSAA-COVRKEY.                                                         160407 
 0748.00            COPY COVRKEY.                                                         160407 
 0749.00       *                                                                          160407 
 0750.00            COPY COVRENQSKM.                                                      160407 
 0751.00        01  WSAA-COVRENQKEY.                                                      160407 
 0752.00            COPY COVRENQKEY.                                                      160407 
 0753.00       *                                                                          160407 
 0754.00            COPY DESCSKM.                                                         160407 
 0755.00            COPY CHDRINPSKM.                                                      160407 
 0756.00            COPY CLNTSKM.                                                         160407 
 0757.00       *                                                                          160408 
 0758.00            COPY CLRRWINSKM.                                                      160407 
 0759.00        01  WSAA-CLRRWINKEY.                                                      160408 
 0760.00            COPY CLRRWINKEY.                                                      160408 
 0761.00       *                                                                          160408 
 0762.00            COPY ITEMSKM.                                                         160407 
 0763.00       *                                                                          160407 
 0764.00            COPY ITDMSKM.                                                         160407 
 0765.00        01  WSAA-ITDMKEY.                                                         160407 
 0766.00            COPY ITDMKEY.                                                         160407 
 0767.00       *                                                                          160407 
 0768.00            COPY JCLTSKM.                                                         160407 
 0769.00        01  WSAA-JCLTKEY.                                                         160407 
 0770.00            COPY JCLTKEY.                                                         160407 
 0771.00       *                                                                          160407 
 0772.00            COPY JCTXSKM.                                                         160407 
 0773.00        01  WSAA-JCTXKEY.                                                         160407 
 0774.00            COPY JCTXKEY.                                                         160407 
 0775.00       *                                                                          160407 
 0776.00            COPY LEXTSKM.                                                         160407 
 0777.00            COPY LIFEARCSKM.                                                      160407 
 0778.00            COPY ZAGPCTOSKM.                                                      160407 
 0779.00            COPY ZCHAFLGSKM.                                                      160407 
 0780.00            COPY ZCHDSKM.                                                         160407 
 0781.00            COPY ZMDCSKM.                                                         160407 
 0782.00            COPY ZMDNSKM.                                                         160407 
 0783.00            COPY ZMDPSKM.                                                         160407 
 0784.00            COPY ZNGCSKM.                                                         160407 
 0785.00       *                                                                          160408 
 0786.00            COPY ZNGCCLNSKM.                                                      160407 
 0787.00        01  WSAA-ZNGCCLNKEY.                                                      160408 
 0788.00            COPY ZNGCCLNKEY.                                                      160408 
 0789.00       *                                                                          160408 
 0790.00            COPY ZNGNSKM.                                                         160407 
 0791.00            COPY ZNGPSKM.                                                         160407 
 0792.00            COPY ZNGPCLNSKM.                                                      160407 
 0793.00            COPY ZPTREFCSKM.                                                      160407 
 0794.00       *                                                                          160407 
 0795.00       * Subroutine copybooks                                                     160407 
 0796.00       *                                                                          160407 
 0797.00            COPY DATCON1REC.                                                      160407 
 0798.00            COPY DATCON2REC.                                                      160411 
 0799.00            COPY DATCON4REC.                                             <ATH999> 180503 
 0800.00       *                                                                          160407 
 0801.00       * Table copybooks                                                          160407 
 0802.00       *                                                                          160407 
 0803.00            COPY T5Z44REC.                                                        160407 
 0804.00            COPY T5Z47REC.                                                        160407 
 0805.00            COPY T5Z48REC.                                                        160407 
 0806.00            COPY T6Z33REC.                                                        160407 
 0807.00            COPY T7Z37REC.                                                        160407 
 0808.00            COPY T7Z38REC.                                                        160407 
 0809.00            COPY T8Z65REC.                                                        160407 
 0810.00       ***  COPY T8Z91REC.                                               <ATHC58> 180516 
 0811.00            COPY T9Z20REC.                                                        160916 
 0812.00            COPY T9Z69REC.                                               <ATHC58> 180516 
 0813.00       *                                                                          160411 
 0814.00       * Batch Parameters                                                         160411 
 0815.00       *                                                                          160411 
 0816.00            COPY P6671PAR.                                                        160411 
 0817.00       *                                                                          160407 
 0818.00       *****************************************************************          160407 
 0819.00       *    L I N K A G E   S E C T I O N                                         160407 
 0820.00       *****************************************************************          160407 
 0821.00       *                                                                          160407 
 0822.00        LINKAGE SECTION.                                                          160407 
 0823.00       *****************                                                          160407 
 0824.00       *                                                                          160407 
 0825.00         01  LSAA-STATUZ                PIC X(04).                                160407 
 0826.00         01  LSAA-BSSCREC               PIC X(1024).                              160407 
 0827.00         01  LSAA-BSPRREC               PIC X(1024).                              160407 
 0828.00         01  LSAA-BPRDREC               PIC X(1024).                              160407 
 0829.00         01  LSAA-BUPAREC               PIC X(1024).                              160407 
 0830.00       /                                                                          160407 
 0831.00        PROCEDURE DIVISION           USING LSAA-STATUZ                            160407 
 0832.00                                           LSAA-BSSCREC                           160407 
 0833.00                                           LSAA-BSPRREC                           160407 
 0834.00                                           LSAA-BPRDREC                           160407 
 0835.00                                           LSAA-BUPAREC.                          160407 
 0836.00                                                                                  160407 
 0837.00            COPY MAINB.                                                           160407 
 0838.00       /                                                                          160407 
 0839.00        500-SQL-ERROR SECTION.                                                    160407 
 0840.00       ***********************                                                    160407 
 0841.00        510-CALL-SYSTEM-ERROR.                                                    160407 
 0842.00       *                                                                          160407 
 0843.00            MOVE SQLCODE                TO SQL-ERROR-CODE                         160407 
 0844.00            MOVE SQL-STATUZ             TO SYSR-SYSERR-STATUZ                     160407 
 0845.00            PERFORM 600-FATAL-ERROR.                                              160407 
 0846.00       *                                                                          160407 
 0847.00        590-EXIT-SQL-ERROR.                                                       160407 
 0848.00            EXIT.                                                                 160407 
 0849.00       /                                                                          160407 
 0850.00        0900-RESTART SECTION.                                                     160407 
 0851.00       **********************                                                     160407 
 0852.00        0900-START.                                                               160407 
 0853.00       *                                                                          160407 
 0854.00       * Place any additional restart processing in here.                         160407 
 0855.00       *                                                                          160407 
 0856.00        0900-EXIT.                                                                160407 
 0857.00            EXIT.                                                                 160407 
 0858.00       /                                                                          160407 
 0859.00        1000-INITIALISE SECTION.                                                  160407 
 0860.00       *************************                                                  160407 
 0861.00        1010-START.                                                               160407 
 0862.00       *                                                                          160407 
 0863.00       * Set status to ok                                                         160407 
 0864.00       *                                                                          160407 
 0865.00            MOVE O-K                    TO WSSP-EDTERROR.                         160407 
 0866.00       *                                                                          160407 
 0867.00       * Initialize w/s fields                                                    160407 
 0868.00       *                                                                          160407 
 0869.00            INITIALIZE                     WSAA-VARIABLES.                        160407 
 0870.00            MOVE SPACE                  TO WSAA-PROCESSING-FLAG.                  160411 
 0871.00       *                                                                          160407 
 0872.00       * Open Files                                                               160407 
 0873.00       *                                                                          160407 
 0874.00            OPEN INPUT LPELCMP3.                                                  160407 
 0875.00       *                                                                          160411 
 0876.00        1020-PARAMETERS.                                                          160411 
 0877.00       *                                                                          160411 
 0878.00       * Since this program runs from a parameter screen move the                 160411 
 0879.00       * internal parameter area to the original parameter copybook               160411 
 0880.00       * to retrieve the contract range.                                          160411 
 0881.00       *                                                                          160411 
 0882.00            MOVE LSAA-BUPAREC           TO BUPA-DATA-AREA.                        160411 
 0883.00            MOVE BUPA-PARMAREA          TO P6671-PARM-RECORD.                     160411 
 0884.00       *                                                                          160411 
 0885.00            MOVE P6671-CHDRNUM          TO WSAA-CHDRNUM-FROM.                     160411 
 0886.00            MOVE P6671-CHDRNUM-1        TO WSAA-CHDRNUM-TO.                       160411 
 0887.00       *                                                                          160411 
 0888.00            IF  P6671-CHDRNUM            = SPACES                                 160411 
 0889.00                MOVE LOW-VALUES         TO WSAA-CHDRNUM-FROM                      160411 
 0890.00            END-IF.                                                               160411 
 0891.00       *                                                                          160411 
 0892.00            IF  P6671-CHDRNUM-1          = SPACES                                 160411 
 0893.00                MOVE HIGH-VALUES        TO WSAA-CHDRNUM-TO                        160411 
 0894.00            END-IF.                                                               160411 
 0895.00       *                                                                          160411 
 0896.00        1030-DATA-AREAS.                                                          160411 
 0897.00       *                                                                          160407 
 0898.00       * Read *ZMDDATE72 Dataara                                                  160407 
 0899.00       *                                                                          160407 
 0900.00            CALL 'JRTVZMD72'         USING WSAA-DATAREA-DATE.                     160407 
 0901.00       *                                                                          160407 
 0902.00       * Read *ZMDSEQ Dataara                                                     160407 
 0903.00       *                                                                          160407 
 0904.00            CALL 'JRTVSEQ72'         USING WSAA-SEQNUM.                           160407 
 0905.00       *                                                                          160411 
 0906.00        1050-SETUP-PTRN-READ.                                                     160411 
 0907.00       *                                                                          160407 
 0908.00       * Break the date to 6 chars and move it to Transaction                     160407 
 0909.00       * Date of ZPTREFC.                                                         160407 
 0910.00       *                                                                          160407 
 0911.00            MOVE WSAA-DATAREA-DATE      TO WSAA-TRANS-DATE-NEW.                   160407 
 0912.00            MOVE WSAA-TRANS-YEAR        TO WSAA-BREAK-YEAR.                       160407 
 0913.00            MOVE WSAA-TRANS-MONTH       TO WSAA-BREAK-MONTH.                      160407 
 0914.00            MOVE WSAA-TRANS-DAY         TO WSAA-BREAK-DAY.                        160407 
 0915.00            MOVE WSAA-BREAK-DATE        TO WSAA-TRANS-DATE.                       160407 
 0916.00       *                                                                          160407 
 0917.00       * Move fields to primary file key,check for modification on contract       160407 
 0918.00       *                                                                          160407 
 0919.00            INITIALIZE                     ZPTREFC-PARAMS.                        160407 
 0920.00            MOVE BPRD-COMPANY           TO ZPTREFC-CHDRCOY.                       160407 
 0921.00            MOVE WSAA-TRANS-DATE        TO ZPTREFC-TRANSACTION-DATE.              160407 
 0922.00            MOVE ZPTREFCREC             TO ZPTREFC-FORMAT.                        160407 
 0923.00            MOVE BEGN                   TO ZPTREFC-FUNCTION.                      160407 
 0924.00       *                                                                          160407 
 0925.00        1090-EXIT.                                                                160407 
 0926.00            EXIT.                                                                 160407 
 0927.00       /                                                                          160407 
 0928.00        2000-READ-FILE SECTION.                                                   160407 
 0929.00       ************************                                                   160407 
 0930.00        2010-START.                                                               160407 
 0931.00       *                                                                          160407 
 0932.00       * Call the I/O module or do a Standard COBOL read on                       160407 
 0933.00       * the primary file.                                                        160407 
 0934.00       *                                                                          160407 
 0935.00            IF  WSAA-SQL-STAT            = ENDP                                   160407 
 0936.00                MOVE ENDP               TO WSSP-EDTERROR                          160407 
 0937.00            END-IF.                                                               160407 
 0938.00       *                                                                          160407 
 0939.00        2090-EXIT.                                                                160407 
 0940.00            EXIT.                                                                 160407 
 0941.00       /                                                                          160407 
 0942.00        2500-EDIT SECTION.                                                        160407 
 0943.00       *******************                                                        160407 
 0944.00        2510-START.                                                               160407 
 0945.00       *                                                                          160407 
 0946.00       * Check record is required for processing.                                 160407 
 0947.00       * Softlock the record if it is to be updated.                              160407 
 0948.00       *                                                                          160407 
 0949.00            MOVE O-K                    TO WSSP-EDTERROR.                         160407 
 0950.00       *                                                                          160407 
 0951.00        2590-EXIT.                                                                160407 
 0952.00            EXIT.                                                                 160407 
 0953.00       /                                                                          160407 
 0954.00        3000-UPDATE SECTION.                                                      160407 
 0955.00       *********************                                                      160407 
 0956.00        3010-START.                                                               160407 
 0957.00       *                                                                          160407 
 0958.00       * Process all transactions for the dates specified                         160407 
 0959.00       *                                                                          160407 
 0960.00            SET PTRN-PROCESS-ACTIVE     TO TRUE.                                  160411 
 0961.00            PERFORM 3100-LOOP-ZPTREFC                                             160411 
 0962.00              UNTIL ZPTREFC-STATUZ       = ENDP.                                  160411 
 0963.00       *                                                                          160407 
 0964.00       * Process all client changes                                               160407 
 0965.00       *                                                                          160408 
 0966.00            SET CLNT-PROCESS-ACTIVE     TO TRUE.                                  160408 
 0967.00            PERFORM 8000-MODIFICATION-ON-CLIENT.                                  160411 
 0968.00       *                                                                          160407 
 0969.00       * Process all IBAN changes                                                 160407 
 0970.00       *                                                                          160408 
 0971.00            SET IBAN-PROCESS-ACTIVE     TO TRUE.                                  160408 
 0972.00            PERFORM 8500-CHECK-FOR-IBAN.                                          160411 
 0973.00       *                                                                          160411 
 0974.00       * All processing completed so move space to process flag.                  160411 
 0975.00       *                                                                          160411 
 0976.00            MOVE SPACE                  TO WSAA-PROCESSING-FLAG.                  160411 
 0977.00       *                                                                          160411 
 0978.00       * Set SQL processing status to ENDP                                        160411 
 0979.00       *                                                                          160411 
 0980.00            MOVE ENDP                   TO WSAA-SQL-STAT.                         160411 
 0981.00       *                                                                          160407 
 0982.00        3050-UPDATE-DATA-AREA.                                                    160411 
 0983.00       *                                                                          160411 
 0984.00       * Change the date of the Dataarea with the Effective date                  160407 
 0985.00       * from the Schedule.                                                       160407 
 0986.00       *                                                                          160407 
 0987.00       * Comment out the update in Data area. It will be updated form    <ATHC84> 180802 
 0988.00       * the last program of scedule.                                    <ATHC84> 180802 
 0989.00       **** MOVE BSSC-EFFECTIVE-DATE    TO WSAA-DATAREA-DATE.            <ATHC84> 180802 
 0990.00       *                                                                          160407 
 0991.00       **** CALL 'JCHGZMD72'         USING WSAA-DATAREA-DATE.            <ATHC84> 180802 
 0992.00       *                                                                          160407 
 0993.00       * Change the value of Sequence Number in ZMDSEQ72 dataarea.                160407 
 0994.00       *                                                                          160407 
 0995.00            CALL 'JCHGSEQ72'         USING WSAA-SEQNUM.                           160407 
 0996.00       *                                                                          160407 
 0997.00        3090-EXIT.                                                                160407 
 0998.00            EXIT.                                                                 160407 
 0999.00       /                                                                          160407 
 1000.00        3100-LOOP-ZPTREFC SECTION.                                                160407 
 1001.00       ***************************                                                160407 
 1002.00        3110-START.                                                               160407 
 1003.00       *                                                                          160407 
 1004.00            PERFORM X100-ZPTREFC-IO                                               160916 
 1005.00       *                                                                          160407 
 1006.00       * If eof reached then exit processing                                      160407 
 1007.00       *                                                                          160407 
 1008.00            IF  ZPTREFC-STATUZ           = ENDP                                   160407 
 1009.00                GO TO 3190-EXIT                                                   160407 
 1010.00            END-IF                                                                160916 
 1011.00       *                                                                          160407 
 1012.00       * Setup next read of ZPTREFC                                               160407 
 1013.00       *                                                                          160407 
 1014.00            MOVE NEXTR                  TO ZPTREFC-FUNCTION                       160916 
 1015.00       *                                                                          160411 
 1016.00       * Check that contract no is within parameter range (if entered)            160411 
 1017.00       * else get next PTRN                                                       160411 
 1018.00       *                                                                          160411 
 1019.00            IF  ZPTREFC-CHDRNUM          < WSAA-CHDRNUM-FROM                      160411 
 1020.00            OR  ZPTREFC-CHDRNUM          > WSAA-CHDRNUM-TO                        160411 
 1021.00                GO TO 3190-EXIT                                                   160411 
 1022.00            END-IF                                                                160916 
 1023.00       *                                                                          160407 
 1024.00       * Change the Transaction Date (ZPTREFC) to 8 chars.                        160407 
 1025.00       *                                                                          160407 
 1026.00            MOVE ZPTREFC-TRANSACTION-DATE                                         160407 
 1027.00                                        TO WSAA-TRANS-DATE                        160916 
 1028.00            MOVE WSAA-TRANS-DATE        TO WSAA-BREAK-DATE                        160916 
 1029.00            MOVE WSCC-20                TO WSAA-TRANS-YEAR20                      160916 
 1030.00            MOVE WSAA-BREAK-YEAR        TO WSAA-TRANS-YEAR                        160916 
 1031.00            MOVE WSAA-BREAK-MONTH       TO WSAA-TRANS-MONTH                       160916 
 1032.00            MOVE WSAA-BREAK-DAY         TO WSAA-TRANS-DAY                         160916 
 1033.00       *                                                                          160407 
 1034.00       * Transaction date must be > dataarea date <= batch effdate                160407 
 1035.00       * otherwise we get the next PTRN                                           160407 
 1036.00       *                                                                          160407 
 1037.00            IF  WSAA-TRANS-DATE-NEW      > BSSC-EFFECTIVE-DATE                    160407 
 1038.00            OR  WSAA-TRANS-DATE-NEW     <= WSAA-DATAREA-DATE                      160407 
 1039.00                GO TO 3190-EXIT                                                   160407 
 1040.00            END-IF                                                                160916 
 1041.00       *                                                                          160407 
 1042.00       * Store PTRN fields in w/s                                                 160407 
 1043.00       *                                                                          160407 
 1044.00            MOVE ZPTREFC-CHDRNUM        TO WSAA-WORK-CHDRNUM                      160916 
 1045.00            MOVE ZPTREFC-BATCTRCDE      TO WS88-BATCTRCDE                         160916 
 1046.00            MOVE ZPTREFC-PTRNEFF        TO WSAA-WORK-EFFDATE                      160916 
 1047.00       *                                                                          160407 
 1048.00       * Check if the Transaction Code is on T5Z47. If not then                   160407 
 1049.00       * we get the next PTRN record                                              160407 
 1050.00       *                                                                          160407 
 1051.00            INITIALIZE                     ITEM-PARAMS                            160916 
 1052.00            MOVE SMTP-ITEM              TO ITEM-ITEMPFX                           160916 
 1053.00            MOVE BPRD-COMPANY           TO ITEM-ITEMCOY                           160916 
 1054.00            MOVE T5Z47                  TO ITEM-ITEMTABL                          160916 
 1055.00            MOVE ZPTREFC-BATCTRCDE      TO ITEM-ITEMITEM                          160916 
 1056.00       *                                                                          160407 
 1057.00            MOVE READR                  TO ITEM-FUNCTION                          160916 
 1058.00            PERFORM I100-ITEMIO                                                   160916 
 1059.00       *                                                                          160407 
 1060.00            IF  ITEM-STATUZ          NOT = O-K                                    160407 
 1061.00                GO TO 3190-EXIT                                                   160407 
 1062.00            END-IF                                                                160916 
 1063.00       *                                                                          160407 
 1064.00            MOVE ITEM-GENAREA           TO T5Z47-T5Z47-REC                        160916 
 1065.00       *                                                                          160407 
 1066.00       * Get contract & agent details                                             160407 
 1067.00       *                                                                          160407 
 1068.00            PERFORM 3200-READ-CHDRINP                                             160916 
 1069.00                                                                                  160913 
 1070.00            IF  DONT-PROCESS-RECORD                                               160913 
 1071.00                GO TO 3190-EXIT                                                   160913 
 1072.00            END-IF                                                                160916 
 1073.00            PERFORM 3300-READ-ZCHAFLG                                             160916 
 1074.00       *                                                                          160407 
 1075.00       * Check rules                                                              160407 
 1076.00       *                                                                          160407 
 1077.00            PERFORM 3400-CHECK-RULES                                              160916 
 1078.00       *                                                                          160407 
 1079.00       * If record is not allowed for some reason then get next                   160407 
 1080.00       *                                                                          160407 
 1081.00            IF  DONT-PROCESS-RECORD                                               160407 
 1082.00                GO TO 3190-EXIT                                                   160407 
 1083.00            END-IF                                                                160916 
 1084.00       *                                                                          160407 
 1085.00       * Collections are only applicable for direct sales products                160407 
 1086.00       * if T8Z91 indicator is set to Y (Yes).                                    160407 
 1087.00       * if T9Z69 indicator is set to Y (Yes).                           <ATHC58> 180516 
 1088.00       *                                                                          160407 
 1089.00            IF  TRAN-COLLECTION                                                   160407 
 1090.00       ***      IF  T8Z91-FOUND                                          <ATHC58> 180516 
 1091.00       ***      AND T8Z91-ZFPIND         = WSCC-Y                        <ATHC58> 180516 
 1092.00                IF  T9Z69-FOUND                                          <ATHC58> 180516 
 1093.00                AND T9Z69-ZFPIND         = WSCC-Y                        <ATHC58> 180516 
 1094.00                    CONTINUE                                                      160407 
 1095.00                ELSE                                                              160407 
 1096.00                    GO TO 3190-EXIT                                               160407 
 1097.00                END-IF                                                            160407 
 1098.00            END-IF                                                                160916 
 1099.00       *                                                                          160407 
 1100.00       * If Contract Issue tran code (T642) and contract has lapsed               160407 
 1101.00       * in the meantime then we do not process                                   160407 
 1102.00       *                                                                          160407 
 1103.00            IF  TRAN-ISSUE                                                        160407 
 1104.00            AND CONTRACT-LAPSED                                                   160407 
 1105.00                GO TO 3190-EXIT                                                   160407 
 1106.00            END-IF.                                                               160407 
 1107.00       *                                                                          160407 
 1108.00        3140-CHECK-LIVES.                                                         160407 
 1109.00       *                                                                          160407 
 1110.00       * Find the main life & all valid lives for the contract                    160407 
 1111.00       *                                                                          160407 
 1112.00            PERFORM 3700-CHECK-LIVES                                              160916 
 1113.00       *                                                                          160407 
 1114.00       * If contract has no lives for some reason then get next PTRN              160407 
 1115.00       *                                                                          160407 
 1116.00            IF  WSAA-TOT-LIVES           = 0                                      160407 
 1117.00                GO TO 3190-EXIT                                                   160407 
 1118.00            END-IF                                                                160916 
 1119.00       *                                                                          160407 
 1120.00       * If no valid coverage was found for this transaction                      160407 
 1121.00       * according to T5Z47 rules then get next PTRN rec                          160407 
 1122.00       *                                                                          160407 
 1123.00            IF  NOT-COVERAGE-LEVEL                                                160407 
 1124.00                GO TO 3190-EXIT                                                   160407 
 1125.00            END-IF.                                                               160407 
 1126.00       *                                                                          160407 
 1127.00        3150-EXTRACT-DETAILS.                                                     160407 
 1128.00       *                                                                          160407 
 1129.00       * Create new MEDNET and ING Policy, Member & Note details                  160407 
 1130.00       * for this contract                                                        160407 
 1131.00       *                                                                          160407 
 1132.00            PERFORM 5000-EXTRACT-DETAILS                                          160916 
 1133.00            .                                                                     160916 
 1134.00       *                                                                          160407 
 1135.00        3190-EXIT.                                                                160407 
 1136.00             EXIT.                                                                160407 
 1137.00       /                                                                          160407 
 1138.00        3200-READ-CHDRINP SECTION.                                                160407 
 1139.00       ***************************                                                160407 
 1140.00        3210-START.                                                               160407 
 1141.00       *                                                                          160407 
 1142.00            SET PROCESS-RECORD          TO TRUE                                   160913 
 1143.00            INITIALIZE                     CHDRINP-PARAMS                         160916 
 1144.00            MOVE BSPR-COMPANY           TO CHDRINP-CHDRCOY                        160916 
 1145.00            MOVE WSAA-WORK-CHDRNUM      TO CHDRINP-CHDRNUM                        160916 
 1146.00            MOVE CHDRINPREC             TO CHDRINP-FORMAT                         160916 
 1147.00            MOVE READR                  TO CHDRINP-FUNCTION                       160916 
 1148.00       *                                                                          160407 
 1149.00            CALL 'CHDRINPIO'         USING CHDRINP-PARAMS                         160916 
 1150.00       *                                                                          160407 
 1151.00            IF  CHDRINP-STATUZ       NOT = O-K                                    160407 
 1152.00            AND CHDRINP-STATUZ       NOT = MRNF                                   160913 
 1153.00                MOVE CHDRINP-PARAMS     TO SYSR-PARAMS                            160407 
 1154.00                MOVE CHDRINP-STATUZ     TO SYSR-STATUZ                            160407 
 1155.00                PERFORM 600-FATAL-ERROR                                           160407 
 1156.00            END-IF                                                                160916 
 1157.00                                                                                  160913 
 1158.00            IF  CHDRINP-STATUZ       NOT = O-K                                    160913 
 1159.00                SET DONT-PROCESS-RECORD TO TRUE                                   160913 
 1160.00                MOVE SPACES             TO WS88-STATCODE                          160913 
 1161.00                GO TO 3290-EXIT                                                   160913 
 1162.00            END-IF                                                                160913 
 1163.00       *                                                                          160407 
 1164.00       * Save contract details in w/s                                             160407 
 1165.00       *                                                                          160407 
 1166.00            MOVE CHDRINP-CHDRCOY        TO WSAA-WORK-CHDRCOY                      160916 
 1167.00            MOVE CHDRINP-STATCODE       TO WS88-STATCODE                          160916 
 1168.00       *                                                                          160407 
 1169.00       * Get extra contract details                                               160407 
 1170.00       *                                                                          160407 
 1171.00            INITIALIZE                     ZCHD-PARAMS                            160916 
 1172.00            MOVE BSPR-COMPANY           TO ZCHD-CHDRCOY                           160916 
 1173.00            MOVE WSAA-WORK-CHDRNUM      TO ZCHD-CHDRNUM                           160916 
 1174.00            MOVE ZCHDREC                TO ZCHD-FORMAT                            160916 
 1175.00            MOVE READR                  TO ZCHD-FUNCTION                          160916 
 1176.00       *                                                                          160407 
 1177.00            CALL 'ZCHDIO'            USING ZCHD-PARAMS                            160916 
 1178.00       *                                                                          160407 
 1179.00            IF  ZCHD-STATUZ          NOT = O-K                                    160407 
 1180.00                MOVE ZCHD-PARAMS        TO SYSR-PARAMS                            160407 
 1181.00                MOVE ZCHD-STATUZ        TO SYSR-STATUZ                            160407 
 1182.00                PERFORM 600-FATAL-ERROR                                           160407 
 1183.00            END-IF                                                                160916 
 1184.00            .                                                                     160916 
 1185.00       *                                                                          160407 
 1186.00        3290-EXIT.                                                                160407 
 1187.00            EXIT.                                                                 160407 
 1188.00       /                                                                          160407 
 1189.00        3300-READ-ZCHAFLG SECTION.                                                160407 
 1190.00       ***************************                                                160407 
 1191.00        3310-START.                                                               160407 
 1192.00       *                                                                          160407 
 1193.00            INITIALIZE                     ZCHAFLG-PARAMS                         160916 
 1194.00            MOVE BSPR-COMPANY           TO ZCHAFLG-CHDRCOY                        160916 
 1195.00            MOVE WSAA-WORK-CHDRNUM      TO ZCHAFLG-CHDRNUM                        160916 
 1196.00            MOVE ZCHAFLGREC             TO ZCHAFLG-FORMAT                         160916 
 1197.00            MOVE READR                  TO ZCHAFLG-FUNCTION                       160916 
 1198.00       *                                                                          160407 
 1199.00            CALL 'ZCHAFLGIO'         USING ZCHAFLG-PARAMS                         160916 
 1200.00       *                                                                          160407 
 1201.00            IF  ZCHAFLG-STATUZ       NOT = O-K                                    160407 
 1202.00                MOVE ZCHAFLG-PARAMS     TO SYSR-PARAMS                            160407 
 1203.00                MOVE ZCHAFLG-STATUZ     TO SYSR-STATUZ                            160407 
 1204.00                PERFORM 600-FATAL-ERROR                                           160407 
 1205.00            END-IF                                                                160916 
 1206.00       *                                                                          160407 
 1207.00       * Using the servicing agent client no read ZAGP                            160407 
 1208.00       *                                                                          160407 
 1209.00            INITIALIZE                     ZAGPCTO-PARAMS                         160916 
 1210.00            MOVE ZCHAFLG-CLNTNUM        TO ZAGPCTO-CLNTNUM                        160916 
 1211.00            MOVE VRCM-MAX-DATE          TO ZAGPCTO-CURRTO                         160916 
 1212.00            MOVE ZAGPCTOREC             TO ZAGPCTO-FORMAT                         160916 
 1213.00            MOVE READR                  TO ZAGPCTO-FUNCTION                       160916 
 1214.00       *                                                                          160407 
 1215.00            CALL 'ZAGPCTOIO'         USING ZAGPCTO-PARAMS                         160916 
 1216.00       *                                                                          160407 
 1217.00            IF  ZAGPCTO-STATUZ       NOT = O-K                                    160407 
 1218.00                MOVE ZAGPCTO-PARAMS     TO SYSR-PARAMS                            160407 
 1219.00                MOVE ZAGPCTO-STATUZ     TO SYSR-STATUZ                            160407 
 1220.00                PERFORM 600-FATAL-ERROR                                           160407 
 1221.00            END-IF                                                                160916 
 1222.00            .                                                                     160916 
 1223.00       *                                                                          160407 
 1224.00        3390-EXIT.                                                                160407 
 1225.00             EXIT.                                                                160407 
 1226.00       /                                                                          160407 
 1227.00        3400-CHECK-RULES SECTION.                                                 160407 
 1228.00       **************************                                                 160407 
 1229.00        3410-START.                                                               160407 
 1230.00       *                                                                          160407 
 1231.00       * Check if extra process rules apply to this contract type                 160407 
 1232.00       *                                                                          160407 
 1233.00            SET PROCESS-RECORD          TO TRUE                                   160916 
 1234.00            SET T8Z65-NOT-FOUND         TO TRUE                                   160916 
 1235.00       ***  SET T8Z91-NOT-FOUND         TO TRUE                          <ATHC58> 180516 
 1236.00            SET T9Z69-NOT-FOUND         TO TRUE                          <ATHC58> 180516 
 1237.00       *                                                                          160407 
 1238.00            INITIALIZE                     ITDM-PARAMS                            160407 
 1239.00                                           WSKY-ITDM-KEY                          160916 
 1240.00            MOVE CHDRINP-CHDRCOY        TO ITDM-ITEMCOY                           160916 
 1241.00            MOVE T8Z65                  TO ITDM-ITEMTABL                          160916 
 1242.00            MOVE CHDRINP-CNTTYPE        TO ITDM-ITEMITEM                          160916 
 1243.00            MOVE CHDRINP-OCCDATE        TO ITDM-ITMFRM                            160916 
 1244.00            MOVE ITDM-DATA-KEY          TO WSKY-ITDM-KEY                          160916 
 1245.00       *                                                                          160407 
 1246.00            MOVE BEGN                   TO ITDM-FUNCTION                          160916 
 1247.00            PERFORM I200-ITDMIO                                                   160916 
 1248.00       *                                                                          160407 
 1249.00       * If T8Z65 item found then set relevant ind to true else exit              160407 
 1250.00       *                                                                          160407 
 1251.00            IF  ITDM-STATUZ              = O-K                                    160407 
 1252.00            AND ITDM-ITEMCOY             = WSKY-ITDM-ITEMCOY                      160407 
 1253.00            AND ITDM-ITEMTABL            = WSKY-ITDM-ITEMTABL                     160407 
 1254.00            AND ITDM-ITEMITEM            = WSKY-ITDM-ITEMITEM                     160407 
 1255.00                SET T8Z65-FOUND         TO TRUE                                   160407 
 1256.00                MOVE ITDM-GENAREA       TO T8Z65-T8Z65-REC                        160407 
 1257.00            ELSE                                                                  160407 
 1258.00                GO TO 3490-EXIT                                                   160407 
 1259.00            END-IF                                                                160916 
 1260.00       *                                                                          160407 
 1261.00       * We have extra process rules for this contract. We now check              160407 
 1262.00       * if extra process rule exist for the source of business                   160407 
 1263.00       *                                                                          160407 
 1264.00       **   INITIALIZE                     ITDM-PARAMS                   <ATHC58> 180516 
 1265.00       **                                  WSKY-ITDM-KEY                 <ATHC58> 180516 
 1266.00       **   MOVE CHDRINP-CHDRCOY        TO ITDM-ITEMCOY                  <ATHC58> 180516 
 1267.00       **   MOVE T8Z91                  TO ITDM-ITEMTABL                 <ATHC58> 180516 
 1268.00       **   MOVE CHDRINP-SRCEBUS        TO WSAA-T8Z91-SRCEBUS            <ATHC58> 180516 
 1269.00       **   MOVE CHDRINP-CNTTYPE        TO WSAA-T8Z91-CNTTYPE            <ATHC58> 180516 
 1270.00       **   MOVE WSAA-T8Z91-ITEM        TO ITDM-ITEMITEM                 <ATHC58> 180516 
 1271.00       **   MOVE CHDRINP-OCCDATE        TO ITDM-ITMFRM                   <ATHC58> 180516 
 1272.00       **   MOVE ITDM-DATA-KEY          TO WSKY-ITDM-KEY                 <ATHC58> 180516 
 1273.00       *                                                                          160407 
 1274.00       **   MOVE BEGN                   TO ITDM-FUNCTION                 <ATHC58> 180516 
 1275.00       **   PERFORM I200-ITDMIO                                          <ATHC58> 180516 
 1276.00       *                                                                          160407 
 1277.00       * If T8Z91 item exists then set relevant ind to true else exit             160407 
 1278.00       *                                                                          160407 
 1279.00       **   IF  ITDM-STATUZ              = O-K                           <ATHC58> 180516 
 1280.00       **   AND ITDM-ITEMCOY             = WSKY-ITDM-ITEMCOY             <ATHC58> 180516 
 1281.00       **   AND ITDM-ITEMTABL            = WSKY-ITDM-ITEMTABL            <ATHC58> 180516 
 1282.00       **   AND ITDM-ITEMITEM            = WSKY-ITDM-ITEMITEM            <ATHC58> 180516 
 1283.00       **       SET T8Z91-FOUND         TO TRUE                          <ATHC58> 180516 
 1284.00       **       MOVE ITDM-GENAREA       TO T8Z91-T8Z91-REC               <ATHC58> 180516 
 1285.00       **   ELSE                                                         <ATHC58> 180516 
 1286.00       **       GO TO 3490-EXIT                                          <ATHC58> 180516 
 1287.00       **   END-IF.                                                      <ATHC58> 180516 
 1288.00                                                                         <ATHC58> 180516 
 1289.00            INITIALIZE                     ITDM-PARAMS                   <ATHC58> 180516 
 1290.00                                           WSKY-ITDM-KEY                 <ATHC58> 180516 
 1291.00            MOVE CHDRINP-CHDRCOY        TO ITDM-ITEMCOY                  <ATHC58> 180516 
 1292.00            MOVE T9Z69                  TO ITDM-ITEMTABL                 <ATHC58> 180516 
 1293.00            MOVE CHDRINP-SRCEBUS        TO WSAA-T9Z69-SRCEBUS            <ATHC58> 180516 
 1294.00            MOVE CHDRINP-CNTTYPE        TO WSAA-T9Z69-CNTTYPE            <ATHC58> 180516 
 1295.00            MOVE WSAA-T9Z69-ITEM        TO ITDM-ITEMITEM                 <ATHC58> 180516 
 1296.00            MOVE CHDRINP-OCCDATE        TO ITDM-ITMFRM                   <ATHC58> 180516 
 1297.00            MOVE ITDM-DATA-KEY          TO WSKY-ITDM-KEY                 <ATHC58> 180516 
 1298.00       *                                                                 <ATHC58> 180516 
 1299.00            MOVE BEGN                   TO ITDM-FUNCTION                 <ATHC58> 180516 
 1300.00            PERFORM I200-ITDMIO                                          <ATHC58> 180516 
 1301.00       *                                                                 <ATHC58> 180516 
 1302.00       * If T9Z69 item exists then set relevant ind to true else exit    <ATHC58> 180516 
 1303.00       *                                                                 <ATHC58> 180516 
 1304.00            IF  ITDM-STATUZ              = O-K                           <ATHC58> 180516 
 1305.00            AND ITDM-ITEMCOY             = WSKY-ITDM-ITEMCOY             <ATHC58> 180516 
 1306.00            AND ITDM-ITEMTABL            = WSKY-ITDM-ITEMTABL            <ATHC58> 180516 
 1307.00            AND ITDM-ITEMITEM            = WSKY-ITDM-ITEMITEM            <ATHC58> 180516 
 1308.00                SET T9Z69-FOUND         TO TRUE                          <ATHC58> 180516 
 1309.00                MOVE ITDM-GENAREA       TO T9Z69-T9Z69-REC               <ATHC58> 180516 
 1310.00            ELSE                                                         <ATHC58> 180516 
 1311.00                GO TO 3490-EXIT                                          <ATHC58> 180516 
 1312.00            END-IF.                                                      <ATHC58> 180516 
 1313.00       *                                                                          160407 
 1314.00        3440-DELIVERY-DATE-CHECK.                                                 160407 
 1315.00       *                                                                          160407 
 1316.00       * If we reach this point then extra product and business rules             160407 
 1317.00       * apply to the contract (ie Direct Sales contract). For such               160407 
 1318.00       * contracts, we only start sending extract details to MEDNET               160407 
 1319.00       * when we have a valid contract delivery date.                             160407 
 1320.00       *                                                                          160407 
 1321.00            IF  ZCHD-ZDLVYDTE            = VRCM-MAX-DATE                          160407 
 1322.00            OR  ZCHD-ZDLVYDTE            = ZEROS                                  160407 
 1323.00                SET DONT-PROCESS-RECORD TO TRUE                                   160407 
 1324.00                GO TO 3490-EXIT                                                   160407 
 1325.00            END-IF.                                                               160407 
 1326.00       *                                                                          160407 
 1327.00        3450-FIRST-PAYMENT-CHECK.                                                 160407 
 1328.00       *                                                                          160407 
 1329.00       * Following only applies to collection transactions (B522)                 160407 
 1330.00       *                                                                          160407 
 1331.00            IF  NOT TRAN-COLLECTION                                               160407 
 1332.00                GO TO 3490-EXIT                                                   160407 
 1333.00            END-IF                                                                160916 
 1334.00       *                                                                          160407 
 1335.00       * Call DATCON2 to get occdate + 1 frequency                                160407 
 1336.00       *                                                                          160407 
 1337.00       ***  INITIALIZE                     DTC2-DATCON2-REC              <ATH999> 180503 
 1338.00       ***  MOVE CHDRINP-OCCDATE        TO DTC2-INT-DATE-1               <ATH999> 180503 
 1339.00       ***  MOVE CHDRINP-BILLFREQ       TO DTC2-FREQUENCY                <ATH999> 180503 
 1340.00       ***  MOVE WSCC-1                 TO DTC2-FREQ-FACTOR              <ATH999> 180503 
 1341.00       *                                                                          160407 
 1342.00       ***  CALL 'DATCON2'           USING DTC2-DATCON2-REC              <ATH999> 180503 
 1343.00       *                                                                          160407 
 1344.00       ***  IF  DTC2-STATUZ          NOT = O-K                           <ATH999> 180503 
 1345.00       ***      MOVE DTC2-DATCON2-REC   TO SYSR-PARAMS                   <ATH999> 180503 
 1346.00       ***      MOVE DTC2-STATUZ        TO SYSR-STATUZ                   <ATH999> 180503 
 1347.00       ***      PERFORM 600-FATAL-ERROR                                  <ATH999> 180503 
 1348.00       ***  END-IF                                                       <ATH999> 180503 
 1349.00       *                                                                          160407 
 1350.00       ***  MOVE DTC2-INT-DATE-2        TO WSAA-FIRST-INST-DATE          <ATH999> 180503 
 1351.00                                                                         <ATH999> 180503 
 1352.00            INITIALIZE                     DTC4-DATCON4-REC              <ATH999> 180503 
 1353.00            MOVE CHDRINP-OCCDATE        TO WSAA-OCCDATE                  <ATH999> 180503 
 1354.00            MOVE CHDRINP-OCCDATE        TO DTC4-INT-DATE-1               <ATH999> 180503 
 1355.00            MOVE CHDRINP-BILLFREQ       TO DTC4-FREQUENCY                <ATH999> 180503 
 1356.00            MOVE WSCC-1                 TO DTC4-FREQ-FACTOR              <ATH999> 180503 
 1357.00            MOVE WSAA-OCCMON            TO DTC4-BILLMONTH-NUM            <ATH999> 180503 
 1358.00            MOVE WSAA-OCCDAY            TO DTC4-BILLDAY-NUM              <ATH999> 180503 
 1359.00       *                                                                 <ATH999> 180503 
 1360.00            CALL 'DATCON4'           USING DTC4-DATCON4-REC              <ATH999> 180503 
 1361.00       *                                                                 <ATH999> 180503 
 1362.00            IF  DTC4-STATUZ          NOT = O-K                           <ATH999> 180503 
 1363.00                MOVE DTC4-DATCON4-REC   TO SYSR-PARAMS                   <ATH999> 180503 
 1364.00                MOVE DTC4-STATUZ        TO SYSR-STATUZ                   <ATH999> 180503 
 1365.00                PERFORM 600-FATAL-ERROR                                  <ATH999> 180503 
 1366.00            END-IF                                                       <ATH999> 180503 
 1367.00       *                                                                 <ATH999> 180503 
 1368.00            MOVE DTC4-INT-DATE-2        TO WSAA-FIRST-INST-DATE          <ATH999> 180503 
 1369.00       *                                                                          160407 
 1370.00       * We only select the direct sales contract when the first                  160407 
 1371.00       * installment has been paid                                                160407 
 1372.00       *                                                                          160407 
 1373.00            IF  ZCHD-PTDATE          NOT = WSAA-FIRST-INST-DATE                   160407 
 1374.00                SET DONT-PROCESS-RECORD TO TRUE                                   160407 
 1375.00                GO TO 3490-EXIT                                                   160407 
 1376.00            END-IF                                                                160916 
 1377.00       *                                                                          160407 
 1378.00            .                                                                     160916 
 1379.00        3490-EXIT.                                                                160407 
 1380.00            EXIT.                                                                 160407 
 1381.00       /                                                                          160407 
 1382.00        3500-COMMIT SECTION.                                                      160407 
 1383.00       *********************                                                      160407 
 1384.00        3510-COMMIT.                                                              160407 
 1385.00       *                                                                          160407 
 1386.00       * Place any additional commitment processing in here.                      160407 
 1387.00       *                                                                          160407 
 1388.00        3590-EXIT.                                                                160407 
 1389.00            EXIT.                                                                 160407 
 1390.00       /                                                                          160407 
 1391.00        3600-ROLLBACK SECTION.                                                    160407 
 1392.00       ***********************                                                    160407 
 1393.00        3610-START.                                                               160407 
 1394.00       *                                                                          160407 
 1395.00       * Place any additional rollback processing in here.                        160407 
 1396.00       *                                                                          160407 
 1397.00        3690-EXIT.                                                                160407 
 1398.00            EXIT.                                                                 160407 
 1399.00       /                                                                          160407 
 1400.00        3700-CHECK-LIVES SECTION.                                                 160407 
 1401.00       **************************                                                 160407 
 1402.00        3710-START.                                                               160407 
 1403.00       *                                                                          160407 
 1404.00       * Loop thru LIFEARC in order to store all life client no's                 160407 
 1405.00       * and relation codes in the w/s array.                                     160407 
 1406.00       *                                                                          160407 
 1407.00            SET NOT-COVERAGE-LEVEL      TO TRUE                                   160916 
 1408.00            SET MAIN-LIFE-NOT-FOUND     TO TRUE                                   160916 
 1409.00       *                                                                          160407 
 1410.00            INITIALIZE                     IX                                     160407 
 1411.00                                           WSAA-TOT-LIVES                         160407 
 1412.00                                           WSAA-LIFCNUM-ARRAY                     160407 
 1413.00                                           WSAA-MAIN-LIFCNUM                      160407 
 1414.00                                           WSAA-MAIN-CCSNO                        160407 
 1415.00                                           WSAA-MAIN-CCSNOCL                      160916 
 1416.00       *                                                                          160407 
 1417.00            INITIALIZE                     LIFEARC-PARAMS                         160916 
 1418.00            MOVE BSPR-COMPANY           TO LIFEARC-CHDRCOY                        160916 
 1419.00            MOVE WSAA-WORK-CHDRNUM      TO LIFEARC-CHDRNUM                        160916 
 1420.00            MOVE LIFEARCREC             TO LIFEARC-FORMAT                         160916 
 1421.00            MOVE BEGN                   TO LIFEARC-FUNCTION                       160916 
 1422.00            MOVE O-K                    TO LIFEARC-STATUZ                         160916 
 1423.00       *                                                                          160407 
 1424.00            PERFORM 3800-PROCESS-LIFEARC                                          160407 
 1425.00              UNTIL LIFEARC-STATUZ       = ENDP                                   160916 
 1426.00       *                                                                          160407 
 1427.00       * Store the total no of lives for this contract                            160407 
 1428.00       *                                                                          160407 
 1429.00            MOVE IX                     TO WSAA-TOT-LIVES                         160916 
 1430.00       *                                                                          160407 
 1431.00       * If contract has no lives for some reason then exit                       160407 
 1432.00       *                                                                          160407 
 1433.00            IF  WSAA-TOT-LIVES           = 0                                      160407 
 1434.00                GO TO 3790-EXIT                                                   160407 
 1435.00            END-IF                                                                160916 
 1436.00       *                                                                          160407 
 1437.00       * Check if main life exists (ie relation code = spaces)                    160407 
 1438.00       *                                                                          160407 
 1439.00            PERFORM VARYING IX        FROM 1 BY 1                                 160407 
 1440.00              UNTIL IX                   > WSAA-TOT-LIVES                         160407 
 1441.00                 OR MAIN-LIFE-FOUND                                               160407 
 1442.00               IF WSAA-LIFCNUM-REL(IX)   = SPACES                                 160407 
 1443.00                  SET MAIN-LIFE-FOUND   TO TRUE                                   160407 
 1444.00                  MOVE WSAA-LIFCNUM(IX) TO WSAA-MAIN-LIFCNUM                      160407 
 1445.00                  MOVE WSAA-LIFCNUM-CCSNO(IX)                                     160407 
 1446.00                                        TO WSAA-MAIN-CCSNO                        160407 
 1447.00                  MOVE WSAA-LIFCNUM-CCSNOCL(IX)                                   160407 
 1448.00                                        TO WSAA-MAIN-CCSNOCL                      160407 
 1449.00                 END-IF                                                           160407 
 1450.00            END-PERFORM                                                           160916 
 1451.00       *                                                                          160407 
 1452.00       * Following only applies if T8Z65 exists for contract                      160407 
 1453.00       * ===================================================                      160407 
 1454.00       * If main life does not exist, then we check if an adult                   160407 
 1455.00       * relation exists by checking adult relation codes in T8Z65.               160407 
 1456.00       * The first matching adult relation will be the main life.                 160407 
 1457.00       *                                                                          160407 
 1458.00            PERFORM VARYING IX        FROM 1 BY 1                                 160407 
 1459.00              UNTIL IX                   > WSAA-TOT-LIVES                         160407 
 1460.00                 OR MAIN-LIFE-FOUND                                               160407 
 1461.00              PERFORM VARYING IY       FROM 1 BY 1                                160916 
 1462.00                UNTIL IY                  > WSCC-MAX-REL                          160916 
 1463.00                   OR MAIN-LIFE-FOUND                                             160916 
 1464.00                                                                                  160916 
 1465.00                   IF  T8Z65-FOUND                                                160916 
 1466.00                   AND T8Z65-ZADLRELN(IY) NOT = SPACES                            160916 
 1467.00                   AND WSAA-LIFCNUM-REL(IX)   = T8Z65-ZADLRELN(IY)                160916 
 1468.00                       SET MAIN-LIFE-FOUND   TO TRUE                              160916 
 1469.00                       MOVE WSAA-LIFCNUM(IX) TO WSAA-MAIN-LIFCNUM                 160916 
 1470.00                       MOVE WSAA-LIFCNUM-CCSNO(IX)                                160916 
 1471.00                                        TO WSAA-MAIN-CCSNO                        160407 
 1472.00                       MOVE WSAA-LIFCNUM-CCSNOCL(IX)                              160916 
 1473.00                                        TO WSAA-MAIN-CCSNOCL                      160407 
 1474.00                   END-IF                                                         160916 
 1475.00              END-PERFORM                                                         160916 
 1476.00            END-PERFORM.                                                          160407 
 1477.00       *                                                                          160407 
 1478.00       * If main life does not exist according to the rules above                 160407 
 1479.00       * then our very first life will be our main life.                          160407 
 1480.00       *                                                                          160407 
 1481.00            IF  WSAA-MAIN-LIFCNUM        = SPACES                                 160407 
 1482.00                SET MAIN-LIFE-FOUND     TO TRUE                                   160407 
 1483.00                MOVE WSAA-LIFCNUM(01)   TO WSAA-MAIN-LIFCNUM                      160407 
 1484.00                MOVE WSAA-LIFCNUM-CCSNO(01)                                       160407 
 1485.00                                        TO WSAA-MAIN-CCSNO                        160407 
 1486.00                MOVE WSAA-LIFCNUM-CCSNOCL(01)                                     160407 
 1487.00                                        TO WSAA-MAIN-CCSNOCL                      160407 
 1488.00            END-IF                                                                160916 
 1489.00       *                                                                          160407 
 1490.00       * Setup Mednet Life relation code. Default is 4 (Other).                   160407 
 1491.00       * 1=Principal, 2=Spouse, 3=Child, 4=Other                                  160407 
 1492.00       *                                                                          160407 
 1493.00            PERFORM VARYING IX        FROM 1 BY 1                                 160407 
 1494.00              UNTIL IX                   > WSCC-MAX-LIVES                         160407 
 1495.00                 OR WSAA-LIFCNUM(IX)     = SPACES                                 160407 
 1496.00               PERFORM 3700A-SETUP-LIFE-USERX                                     160407 
 1497.00            END-PERFORM                                                           160916 
 1498.00       *                                                                          160407 
 1499.00            .                                                                     160916 
 1500.00        3790-EXIT.                                                                160407 
 1501.00            EXIT.                                                                 160407 
 1502.00       /                                                                          160407 
 1503.00        3700A-SETUP-LIFE-USERX SECTION.                                           160407 
 1504.00       ********************************                                           160407 
 1505.00        3710A-START.                                                              160407 
 1506.00       *                                                                          160407 
 1507.00       * Setup Mednet Life relation code. Default is 4 (Other).                   160407 
 1508.00       * 1=Principal, 2=Spouse, 3=Child, 4=Other                                  160407 
 1509.00       *                                                                          160407 
 1510.00            MOVE SPACES                 TO WSAA-RELATION-CODE                     160916 
 1511.00            MOVE WSCC-4                 TO WSAA-RELATION-CODE                     160916 
 1512.00       *                                                                          160407 
 1513.00            SET RELATION-NOT-FOUND      TO TRUE                                   160916 
 1514.00       *                                                                          160407 
 1515.00       * If life relation = spaces or lifcnum is equal to w/s main                160407 
 1516.00       * lifcnum found earlier (if not spaces) then set to 1                      160407 
 1517.00       *                                                                          160407 
 1518.00            IF  WSAA-LIFCNUM-REL(IX)     = SPACES                                 160407 
 1519.00            OR  WSAA-LIFCNUM(IX)         = WSAA-MAIN-LIFCNUM                      160407 
 1520.00                SET RELATION-FOUND      TO TRUE                                   160407 
 1521.00                MOVE WSCC-1             TO WSAA-RELATION-CODE                     160407 
 1522.00            END-IF                                                                160916 
 1523.00       *                                                                          160407 
 1524.00       * Following only applies if T8Z65 exists for contract                      160407 
 1525.00       * ===================================================                      160407 
 1526.00       * If adult relation & not Other (ie O) then set to 2 (Spouse)              160407 
 1527.00       *                                                                          160407 
 1528.00            PERFORM VARYING IY        FROM 1 BY 1                                 160407 
 1529.00              UNTIL IY                   > WSCC-MAX-REL                           160407 
 1530.00                 OR RELATION-FOUND                                                160407 
 1531.00              IF  T8Z65-FOUND                                                     160407 
 1532.00              AND WSAA-LIFCNUM-REL(IX)                                            160407 
 1533.00                                     NOT = 'O'                                    160407 
 1534.00              AND WSAA-LIFCNUM-REL(IX)   = T8Z65-ZADLRELN(IY)                     160407 
 1535.00                  SET RELATION-FOUND    TO TRUE                                   160407 
 1536.00                  MOVE WSCC-2           TO WSAA-RELATION-CODE                     160407 
 1537.00             END-IF                                                               160407 
 1538.00            END-PERFORM                                                           160916 
 1539.00       *                                                                          160407 
 1540.00       * Following only applies if T8Z65 exists for contract                      160407 
 1541.00       * ===================================================                      160407 
 1542.00       * If child relation then set to 3 (Child)                                  160407 
 1543.00       *                                                                          160407 
 1544.00            PERFORM VARYING IY        FROM 1 BY 1                                 160407 
 1545.00              UNTIL IY                   > WSCC-MAX-REL                           160913 
 1546.00                 OR RELATION-FOUND                                                160407 
 1547.00                    IF  T8Z65-FOUND                                               160916 
 1548.00                    AND WSAA-LIFCNUM-REL(IX)   = T8Z65-ZCHLRELN(IY)               160916 
 1549.00                        SET RELATION-FOUND    TO TRUE                             160916 
 1550.00                        MOVE WSCC-3           TO WSAA-RELATION-CODE               160916 
 1551.00                    END-IF                                                        160916 
 1552.00            END-PERFORM                                                           160916 
 1553.00       *                                                                          160407 
 1554.00       * Store the life user code in the w/s array                                160407 
 1555.00       *                                                                          160407 
 1556.00            MOVE WSAA-RELATION-CODE     TO WSAA-LIFCNUM-USERX(IX)                 160916 
 1557.00       *                                                                          160407 
 1558.00             .                                                                    160916 
 1559.00        3790A-EXIT.                                                               160407 
 1560.00            EXIT.                                                                 160407 
 1561.00       /                                                                          160407 
 1562.00        3800-PROCESS-LIFEARC SECTION.                                             160407 
 1563.00       ******************************                                             160407 
 1564.00        3810-START.                                                               160407 
 1565.00       *                                                                          160407 
 1566.00            PERFORM X200-LIFEARC-IO                                               160916 
 1567.00       *                                                                          160916 
 1568.00       *                                                                          160407 
 1569.00       * If eof or change of key then exit loop processing                        160408 
 1570.00       *                                                                          160408 
 1571.00            IF  LIFEARC-STATUZ           = ENDP                                   160407 
 1572.00            OR  LIFEARC-CHDRCOY      NOT = BSPR-COMPANY                           160407 
 1573.00            OR  LIFEARC-CHDRNUM      NOT = WSAA-WORK-CHDRNUM                      160408 
 1574.00                MOVE ENDP               TO LIFEARC-STATUZ                         160407 
 1575.00                GO TO 3890-EXIT                                                   160407 
 1576.00            END-IF                                                                160916 
 1577.00       *                                                                          160407 
 1578.00       * Setup next read of logical LIFEARC                                       160408 
 1579.00       *                                                                          160407 
 1580.00            MOVE NEXTR                  TO LIFEARC-FUNCTION                       160916 
 1581.00       *                                                                          160407 
 1582.00       * We are only interested in vf1 records                                    160408 
 1583.00       *                                                                          160407 
 1584.00            IF  LIFEARC-VALIDFLAG    NOT = WSCC-1                                 160408 
 1585.00                GO TO 3890-EXIT                                                   160407 
 1586.00            END-IF                                                                160916 
 1587.00       *                                                                          160408 
 1588.00       * We are only interested in lives which are inforce                        160408 
 1589.00       *                                                                          160408 
 1590.00            IF  NOT CONTRACT-RD                                                   160927 
 1591.00            AND NOT CONTRACT-DH                                                   160927 
 1592.00            IF  LIFEARC-STATCODE     NOT = WSCC-IF                                160408 
 1593.00                GO TO 3890-EXIT                                                   160408 
 1594.00            END-IF                                                                160916 
 1595.00            ELSE                                                                  160927 
 1596.00               IF  LIFEARC-STATCODE NOT = WSCC-DH                                 160927 
 1597.00                   GO TO 3890-EXIT                                                160927 
 1598.00               END-IF                                                             160927 
 1599.00            END-IF                                                                160927 
 1600.00       *                                                                          160407 
 1601.00       * Check if life has a valid coverage for this process.                     160407 
 1602.00       *                                                                          160407 
 1603.00            SET COVERAGE-NOT-FOUND      TO TRUE                                   160916 
 1604.00       *                                                                          160407 
 1605.00            INITIALIZE                     COVRENQ-PARAMS                         160407 
 1606.00                                           COVRENQREC-KEY-DATA                    160407 
 1607.00                                           WSKY-COVRENQ-KEY                       160916 
 1608.00            MOVE LIFEARC-CHDRCOY        TO COVRENQ-CHDRCOY                        160916 
 1609.00            MOVE LIFEARC-CHDRNUM        TO COVRENQ-CHDRNUM                        160916 
 1610.00            MOVE LIFEARC-LIFE           TO COVRENQ-LIFE                           160916 
 1611.00            MOVE COVRENQ-DATA-KEY       TO WSKY-COVRENQ-KEY                       160916 
 1612.00            MOVE COVRENQREC             TO COVRENQ-FORMAT                         160916 
 1613.00            MOVE BEGN                   TO COVRENQ-FUNCTION                       160916 
 1614.00            MOVE O-K                    TO COVRENQ-STATUZ                         160916 
 1615.00       *                                                                          160407 
 1616.00            PERFORM 3900-PROCESS-COVRENQ                                          160407 
 1617.00              UNTIL COVRENQ-STATUZ       = ENDP                                   160407 
 1618.00                 OR COVERAGE-FOUND                                                160916 
 1619.00       *                                                                          160407 
 1620.00       * If no valid coverage found for life get next life record                 160407 
 1621.00       *                                                                          160407 
 1622.00            IF  COVERAGE-NOT-FOUND                                                160407 
 1623.00                GO TO 3890-EXIT                                                   160407 
 1624.00            END-IF                                                                160916 
 1625.00       *                                                                          160407 
 1626.00       * Valid coverage exists for life so store relation code,                   160407 
 1627.00       * life client no & CCS no in w/s array                                     160407 
 1628.00       *                                                                          160407 
 1629.00            ADD  1                      TO IX                                     160916 
 1630.00            MOVE LIFEARC-LIFCNUM        TO WSAA-LIFCNUM(IX)                       160916 
 1631.00            MOVE LIFEARC-LIFE           TO WSAA-LIFCNUM-LIFE(IX)                  160916 
 1632.00            MOVE LIFEARC-JLIFE          TO WSAA-LIFCNUM-JLIFE(IX)                 160916 
 1633.00            MOVE LIFEARC-LIFEREL        TO WSAA-LIFCNUM-REL(IX)                   160916 
 1634.00       *                                                                          160407 
 1635.00       * Store life CCS no                                                        160407 
 1636.00       *                                                                          160407 
 1637.00            MOVE LIFEARC-LIFCNUM        TO WSAA-WORK-CLNTNUM                      160916 
 1638.00            PERFORM 11000-GET-CCSNO                                               160916 
 1639.00            MOVE WSAA-WORK-CCSNO        TO WSAA-LIFCNUM-CCSNO(IX)                 160916 
 1640.00            MOVE WSAA-CLEAN-CCSNO       TO WSAA-LIFCNUM-CCSNOCL(IX)               160916 
 1641.00       *                                                                          160407 
 1642.00       * Store product name from T5Z48                                            160407 
 1643.00       *                                                                          160407 
 1644.00            MOVE T5Z48-ZDESCR(5:1)      TO WSAA-LIFCNUM-PRODN(IX)                 160916 
 1645.00       *                                                                          160407 
 1646.00            .                                                                     160916 
 1647.00        3890-EXIT.                                                                160407 
 1648.00            EXIT.                                                                 160407 
 1649.00       /                                                                          160407 
 1650.00        3900-PROCESS-COVRENQ SECTION.                                             160407 
 1651.00       ******************************                                             160407 
 1652.00        3910-START.                                                               160407 
 1653.00       *                                                                          160407 
 1654.00            PERFORM X300-COVRENQ-IO                                               160916 
 1655.00       *                                                                          160407 
 1656.00       * If eof or change of key then exit loop processing                        160407 
 1657.00       *                                                                          160407 
 1658.00            IF  COVRENQ-STATUZ           = ENDP                                   160407 
 1659.00            OR  COVRENQ-CHDRCOY      NOT = WSKY-COVRENQ-CHDRCOY                   160407 
 1660.00            OR  COVRENQ-CHDRNUM      NOT = WSKY-COVRENQ-CHDRNUM                   160407 
 1661.00            OR  COVRENQ-LIFE         NOT = WSKY-COVRENQ-LIFE                      160407 
 1662.00                MOVE ENDP               TO COVRENQ-STATUZ                         160407 
 1663.00                GO TO 3990-EXIT                                                   160407 
 1664.00            END-IF                                                                160916 
 1665.00       *                                                                          160407 
 1666.00       * Setup next read of COVRENQ logical                                       160407 
 1667.00       *                                                                          160407 
 1668.00            MOVE NEXTR                  TO COVRENQ-FUNCTION                       160916 
 1669.00       *                                                                          160407 
 1670.00       * Check joint life (if spaces then default 00)                             160407 
 1671.00       *                                                                          160407 
 1672.00            IF  COVRENQ-JLIFE            = SPACES                                 160407 
 1673.00                MOVE WSCC-00            TO COVRENQ-JLIFE                          160407 
 1674.00            END-IF                                                                160916 
 1675.00       *                                                                          160407 
 1676.00            IF  COVRENQ-JLIFE        NOT = LIFEARC-JLIFE                          160407 
 1677.00                GO TO 3990-EXIT                                                   160407 
 1678.00            END-IF                                                                160916 
 1679.00       *                                                                          160407 
 1680.00       * Check if MEDNET coverage by reading T5Z48. If item does not              160407 
 1681.00       * exist then get next coverage record for the life.                        160407 
 1682.00       *                                                                          160407 
 1683.00            MOVE COVRENQ-CRTABLE        TO WSAA-WORK-CRTABLE                      160916 
 1684.00            MOVE COVRENQ-RERATE-FROM-DATE                                <ATHC60> 180608 
 1685.00                                        TO WSAA-RERATE-FROM-DATE         <ATHC60> 180608 
 1686.00            PERFORM 13000-READ-T5Z48                                              160916 
 1687.00       *                                                                          160407 
 1688.00       **** IF  ITEM-STATUZ          NOT = O-K                           <ATHC60> 180606 
 1689.00            IF  ITDM-STATUZ          NOT = O-K                           <ATHC60> 180606 
 1690.00                GO TO 3990-EXIT                                                   160407 
 1691.00            END-IF                                                                160916 
 1692.00       *                                                                          160407 
 1693.00       * Following only applies when processing PTRNs                             160408 
 1694.00       * ============================================                             160408 
 1695.00       * If transaction allows coverage level processing then                     160407 
 1696.00       * set relevant indicator to true                                           160407 
 1697.00       *                                                                          160407 
 1698.00            IF  PTRN-PROCESS-ACTIVE                                               160408 
 1699.00                IF  T5Z47-JENTTYP        = WSCC-01                                160408 
 1700.00                OR (T5Z47-JENTTYP        = WSCC-02                                160408 
 1701.00                AND ZPTREFC-TRANNO      <= COVRENQ-TRANNO)                        160408 
 1702.00                    SET COVERAGE-LEVEL  TO TRUE                                   160408 
 1703.00                END-IF                                                            160408 
 1704.00            END-IF                                                                160916 
 1705.00       *                                                                          160407 
 1706.00       * If contract is inforce then we only want inforce coverages               160407 
 1707.00       *                                                                          160407 
 1708.00            IF  CONTRACT-INFORCE                                                  160407 
 1709.00            AND COVRENQ-STATCODE         = WSCC-IF                                160407 
 1710.00                SET COVERAGE-FOUND      TO TRUE                                   160407 
 1711.00            END-IF                                                                160916 
 1712.00       *                                                                          160407 
 1713.00       * If coverage is not inforce then we select all vf1 coverages              160407 
 1714.00       *                                                                          160407 
 1715.00            IF  NOT CONTRACT-INFORCE                                              160411 
 1716.00                SET COVERAGE-FOUND      TO TRUE                                   160407 
 1717.00            END-IF                                                                160916 
 1718.00       *                                                                          160407 
 1719.00            .                                                                     160916 
 1720.00        3990-EXIT.                                                                160407 
 1721.00            EXIT.                                                                 160407 
 1722.00       /                                                                          160407 
 1723.00        4000-CLOSE SECTION.                                                       160407 
 1724.00       ********************                                                       160407 
 1725.00        4010-START.                                                               160407 
 1726.00       *                                                                          160407 
 1727.00       * Close open files                                                         160407 
 1728.00       *                                                                          160407 
 1729.00            CLOSE LPELCMP3                                                        160916 
 1730.00       *                                                                          160407 
 1731.00       * Set status to OK                                                         160407 
 1732.00       *                                                                          160407 
 1733.00            MOVE O-K                    TO LSAA-STATUZ                            160916 
 1734.00       *                                                                          160407 
 1735.00            .                                                                     160916 
 1736.00        4090-EXIT.                                                                160407 
 1737.00            EXIT.                                                                 160407 
 1738.00       /                                                                          160407 
 1739.00        5000-EXTRACT-DETAILS SECTION.                                             160407 
 1740.00       ******************************                                             160407 
 1741.00        5010-START.                                                               160407 
 1742.00       *                                                                          160407 
 1743.00       * Check if we have already created an ZMDP record for this                 160407 
 1744.00       * contract. If so, we exit extraction processing.                          160407 
 1745.00       *                                                                          160407 
 1746.00            INITIALIZE                     ZMDP-PARAMS                            160916 
 1747.00            MOVE WSAA-WORK-CHDRNUM      TO ZMDP-ZPOLICY                           160916 
 1748.00            MOVE READR                  TO ZMDP-FUNCTION                          160916 
 1749.00            PERFORM M100-ZMDPIO                                                   160916 
 1750.00       *                                                                          160407 
 1751.00            IF  ZMDP-STATUZ              = O-K                                    160407 
 1752.00                GO TO 5090-EXIT                                                   160407 
 1753.00            END-IF                                                                160916 
 1754.00       *                                                                          160407 
 1755.00       * If we reach here, we don't have an ZMDP record yet.                      160407 
 1756.00       * Firstly we check if policy details exist (ie ZNGP).                      160407 
 1757.00       *                                                                          160407 
 1758.00            SET ZNGP-NOT-FOUND          TO TRUE                                   160916 
 1759.00       *                                                                          160407 
 1760.00            INITIALIZE                     ZNGP-PARAMS                            160916 
 1761.00            MOVE WSAA-WORK-CHDRNUM      TO ZNGP-ZPOLICY                           160916 
 1762.00            MOVE READR                  TO ZNGP-FUNCTION                          160916 
 1763.00            PERFORM N100-ZNGPIO                                                   160916 
 1764.00       *                                                                          160407 
 1765.00       * If ZNGP does not exist then go to setup new ZNGP record                  160407 
 1766.00       *                                                                          160407 
 1767.00            IF  ZNGP-STATUZ          NOT = O-K                                    160407 
 1768.00                GO TO 5030-CREATE-POLICY-DETAILS                                  160407 
 1769.00            END-IF                                                                160916 
 1770.00       *                                                                          160407 
 1771.00       * If we reach this point then we have an ZNGP for this contract            160407 
 1772.00       * so set relevant ind to true and store the transaction type               160407 
 1773.00       *                                                                          160407 
 1774.00            SET ZNGP-FOUND              TO TRUE                                   160916 
 1775.00            MOVE ZNGP-ZTRNTYP           TO WSAA-ZNGP-ZTRNTYP                      160916 
 1776.00       *                                                                          160407 
 1777.00       * If the main life of the contract has changed then we need                160407 
 1778.00       * to create a new ZMDP record to register that the previous                160407 
 1779.00       * main life have been cancelled                                            160407 
 1780.00       *                                                                          160407 
 1781.00            IF  ZNGP-ZLFCODE         NOT = WSAA-MAIN-CCSNO                        160407 
 1782.00                PERFORM 5100-CRT-CANCELLATION-ZMDP                                160407 
 1783.00            END-IF                                                                160916 
 1784.00       *                                                                          160407 
 1785.00       * Delete current ZNGP record                                               160407 
 1786.00       *                                                                          160407 
 1787.00            MOVE READH                  TO ZNGP-FUNCTION                          160916 
 1788.00            PERFORM N100-ZNGPIO                                                   160916 
 1789.00       *                                                                          160407 
 1790.00            MOVE DELET                  TO ZNGP-FUNCTION                          160916 
 1791.00            PERFORM N100-ZNGPIO.                                                  160407 
 1792.00       *                                                                          160407 
 1793.00        5030-CREATE-POLICY-DETAILS.                                               160407 
 1794.00       *                                                                          160407 
 1795.00       * Get the main life client details & CCS no                                160407 
 1796.00       *                                                                          160407 
 1797.00            IF  ZNGP-NOT-FOUND                                                    161003 
 1798.00            AND NOT CONTRACT-INFORCE                                              161003 
 1799.00                GO TO 5090-EXIT                                                   161003 
 1800.00            END-IF                                                                161003 
 1801.00                                                                                  161003 
 1802.00            MOVE WSAA-MAIN-LIFCNUM      TO WSAA-WORK-CLNTNUM                      160916 
 1803.00            PERFORM 10000-READ-CLNT                                               160916 
 1804.00       *                                                                          160407 
 1805.00       * Create new ZMDP/ZNGP policy details for the main life                    160407 
 1806.00       *                                                                          160407 
 1807.00            PERFORM 5200-CREATE-POLICY-DETAILS.                                   160916 
 1808.00       *                                                                          160407 
 1809.00        5050-MEMBER-DETAILS.                                                      160407 
 1810.00       *                                                                          160407 
 1811.00       * Delete current Life Member details                                       160407 
 1812.00       *                                                                          160407 
 1813.00            SET ZNGC-NOT-FOUND          TO TRUE                                   160916 
 1814.00            INITIALIZE                     IZ                                     160407 
 1815.00                                           WSAA-ZNGC-ARRAY                        160916 
 1816.00       *                                                                          160407 
 1817.00            INITIALIZE                     ZNGC-PARAMS                            160916 
 1818.00            MOVE WSAA-WORK-CHDRNUM      TO ZNGC-ZPOLICY                           160916 
 1819.00            MOVE BEGNH                  TO ZNGC-FUNCTION                          160916 
 1820.00            MOVE O-K                    TO ZNGC-STATUZ                            160916 
 1821.00       *                                                                          160407 
 1822.00            PERFORM 5300-DELETE-ZNGC                                              160407 
 1823.00              UNTIL ZNGC-STATUZ          = ENDP                                   160916 
 1824.00       *                                                                          160407 
 1825.00       * Delete current Life Note details                                         160407 
 1826.00       *                                                                          160407 
 1827.00       **** SET NOT-FOUND-ZNGN          TO TRUE                          <ATHC84> 180806 
 1828.00            INITIALIZE                     ZNGN-I                        <ATHC84> 180806 
 1829.00                                           WSAA-ZNGN-ARRAY               <ATHC84> 180806 
 1830.00                                                                         <ATHC84> 180806 
 1831.00            INITIALIZE                     ZNGN-PARAMS                            160916 
 1832.00            MOVE WSAA-WORK-CHDRNUM      TO ZNGN-ZPOLICY                           160916 
 1833.00            MOVE BEGNH                  TO ZNGN-FUNCTION                          160916 
 1834.00            MOVE O-K                    TO ZNGN-STATUZ                            160916 
 1835.00       *                                                                          160407 
 1836.00            PERFORM 5500-DELETE-ZNGN                                              160407 
 1837.00              UNTIL ZNGN-STATUZ          = ENDP                                   160916 
 1838.00       *                                                                          160407 
 1839.00       * Read thru all lives for this contract which are stored in                160407 
 1840.00       * the life w/s array and create new member and note details                160407 
 1841.00       *                                                                          160407 
 1842.00            PERFORM VARYING IX        FROM 1 BY 1                                 160407 
 1843.00              UNTIL IX                   > WSCC-MAX-LIVES                         160407 
 1844.00                 OR WSAA-LIFCNUM(IX)     = SPACES                                 160407 
 1845.00                    PERFORM 5600-PROCESS-LIVES                                    160916 
 1846.00            END-PERFORM                                                           160916 
 1847.00       *                                                                          160407 
 1848.00            .                                                                     160916 
 1849.00        5090-EXIT.                                                                160407 
 1850.00            EXIT.                                                                 160407 
 1851.00       /                                                                          160407 
 1852.00        5100-CRT-CANCELLATION-ZMDP SECTION.                                       160407 
 1853.00       ************************************                                       160407 
 1854.00        5110-START.                                                               160407 
 1855.00       *                                                                          160407 
 1856.00       * Initialize ZMDP record                                                   160407 
 1857.00       *                                                                          160407 
 1858.00            INITIALIZE                     ZMDP-PARAMS                            160916 
 1859.00       *                                                                          160407 
 1860.00       * Setup fields from current ZNGP                                           160407 
 1861.00       *                                                                          160407 
 1862.00            MOVE ZNGP-ZPOLICY           TO ZMDP-ZPOLICY                           160916 
 1863.00            MOVE ZNGP-CLNTNAME          TO ZMDP-CLNTNAME                          160916 
 1864.00            MOVE ZNGP-ZPOLTYP           TO ZMDP-ZPOLTYP                           160916 
 1865.00            MOVE ZNGP-EFFCDTE           TO ZMDP-EFFCDTE                           160916 
 1866.00            MOVE ZNGP-ZPTDATE           TO ZMDP-ZPTDATE                           160916 
 1867.00            MOVE ZNGP-ZEXPDATE          TO ZMDP-ZEXPDATE                          160916 
 1868.00            MOVE ZNGP-INCDTE            TO ZMDP-INCDTE                            160916 
 1869.00            MOVE ZNGP-ZMDAGY            TO ZMDP-ZMDAGY                            160916 
 1870.00            MOVE ZNGP-ZMDAGNT           TO ZMDP-ZMDAGNT                           160916 
 1871.00            MOVE ZNGP-PRODN             TO ZMDP-PRODN                             160916 
 1872.00            MOVE ZNGP-PAYPLAN           TO ZMDP-PAYPLAN                           160916 
 1873.00            MOVE ZNGP-JENTID            TO ZMDP-JENTID                            160916 
 1874.00            MOVE ZNGP-ZMDADR            TO ZMDP-ZMDADR                            160916 
 1875.00            MOVE ZNGP-ZMDZIP            TO ZMDP-ZMDZIP                            160916 
 1876.00            MOVE ZNGP-ZMDFAX            TO ZMDP-ZMDFAX                            160916 
 1877.00            MOVE ZNGP-ZMDPHA            TO ZMDP-ZMDPHA                            160916 
 1878.00            MOVE ZNGP-ZMDPHB            TO ZMDP-ZMDPHB                            160916 
 1879.00            MOVE ZNGP-ZMDID             TO ZMDP-ZMDID                             160916 
 1880.00            MOVE ZNGP-ZGRPNUM           TO ZMDP-ZGRPNUM                           160916 
 1881.00       *                                                                          160407 
 1882.00       * 10 = Policy Cancellation                                                 160407 
 1883.00       *                                                                          160407 
 1884.00            MOVE SPACES                 TO WSAA-TRAN-TYP                          160916 
 1885.00            MOVE WSCC-CANCL             TO WSAA-TRAN-TYP                          160916 
 1886.00            PERFORM 17000-READ-T9Z20                                              160916 
 1887.00            MOVE T9Z20-ZTRNTYP(1)       TO ZMDP-ZTRNTYP                           160916 
 1888.00                                                                                  160916 
 1889.00       ***  MOVE WSCC-10                TO ZMDP-ZTRNTYP.                          160916 
 1890.00       *                                                                          160407 
 1891.00       * Setup next sequence no                                                   160407 
 1892.00       *                                                                          160407 
 1893.00            ADD WSCC-1                  TO WSAA-SEQNUM                            160916 
 1894.00            PERFORM 15000-DELETE-SEQ-ZEROES                                       160916 
 1895.00            MOVE WSAA-SEQ-NUMBERS       TO ZMDP-ZTRNNUM                           160916 
 1896.00       *                                                                          160407 
 1897.00       * Setup modification date                                                  160407 
 1898.00       *                                                                          160407 
 1899.00            MOVE BSSC-EFFECTIVE-DATE    TO WSAA-DATCON1-DATE                      160916 
 1900.00            MOVE SPACES                 TO WSAA-DESC-DATE                         160916 
 1901.00            MOVE '5100-BSSC'            TO WSAA-DESC-DATE                         160916 
 1902.00            PERFORM 16000-CONVERT-DATE                                            160916 
 1903.00            MOVE DTC1-EXT-DATE          TO ZMDP-ZMODDTE                           160916 
 1904.00       *                                                                          160407 
 1905.00       * Setup cancellation date                                                  160407 
 1906.00       *                                                                          160407 
 1907.00            MOVE WSAA-TRANS-DATE-NEW    TO WSAA-DATCON1-DATE                      160916 
 1908.00            MOVE SPACES                 TO WSAA-DESC-DATE                         160916 
 1909.00            MOVE '5100-ZPTREFC'         TO WSAA-DESC-DATE                         160916 
 1910.00            PERFORM 16000-CONVERT-DATE                                            160916 
 1911.00            MOVE DTC1-EXT-DATE          TO ZMDP-ZCANDTE                           160916 
 1912.00       *                                                                          160407 
 1913.00       * If special processing (ie T514 Lapse or T557 Comp Add)                   160407 
 1914.00       * then modification/cancel dates will be the PTRN effdate                  160407 
 1915.00       *                                                                          160407 
 1916.00            IF  TRAN-SPECIAL                                                      160407 
 1917.00                MOVE WSAA-WORK-EFFDATE  TO WSAA-DATCON1-DATE                      160412 
 1918.00                MOVE SPACES             TO WSAA-DESC-DATE                         160407 
 1919.00                MOVE '5100-ZPTR-EFF'    TO WSAA-DESC-DATE                         160407 
 1920.00                PERFORM 16000-CONVERT-DATE                                        160407 
 1921.00                MOVE DTC1-EXT-DATE      TO ZMDP-ZMODDTE                           160407 
 1922.00                                           ZMDP-ZCANDTE                           160407 
 1923.00            END-IF                                                                160916 
 1924.00       *                                                                          160407 
 1925.00       * Setup remaining fields from ZNGP                                         160407 
 1926.00       *                                                                          160407 
 1927.00            MOVE ZNGP-ZCANTYP           TO ZMDP-ZCANTYP                           160916 
 1928.00            MOVE ZNGP-CONTTYPE          TO ZMDP-CONTTYPE                          160916 
 1929.00            MOVE ZNGP-ZBNKNUM           TO ZMDP-ZBNKNUM                           160916 
 1930.00            MOVE ZNGP-ZMDACCH           TO ZMDP-ZMDACCH                           160916 
 1931.00            MOVE ZNGP-ZCONTR            TO ZMDP-ZCONTR                            160916 
 1932.00            MOVE ZNGP-ZCITY             TO ZMDP-ZCITY                             160916 
 1933.00            MOVE ZNGP-ZCLASS            TO ZMDP-ZCLASS                            160916 
 1934.00            MOVE ZNGP-ZPAYMENT          TO ZMDP-ZPAYMENT                          160916 
 1935.00            MOVE ZNGP-JLBL              TO ZMDP-JLBL                              160916 
 1936.00            MOVE ZNGP-ZACCNUM           TO ZMDP-ZACCNUM                           160916 
 1937.00            MOVE ZNGP-ZPROCL            TO ZMDP-ZPROCL                            160916 
 1938.00            MOVE ZNGP-ZSALENT           TO ZMDP-ZSALENT                           160916 
 1939.00            MOVE ZNGP-ZSERVEN           TO ZMDP-ZSERVEN                           160916 
 1940.00            MOVE ZNGP-ZBUSTYP           TO ZMDP-ZBUSTYP                           160916 
 1941.00            MOVE ZNGP-ZBANKC            TO ZMDP-ZBANKC                            160916 
 1942.00            MOVE ZNGP-ZCRCARD           TO ZMDP-ZCRCARD                           160916 
 1943.00            MOVE ZNGP-ZCARDNUM          TO ZMDP-ZCARDNUM                          160916 
 1944.00            MOVE ZNGP-ZEXPDAT           TO ZMDP-ZEXPDAT                           160916 
 1945.00       *                                                                          160407 
 1946.00       * Write the cancelled owner record in ZMDP file                            160407 
 1947.00       *                                                                          160407 
 1948.00            MOVE WRITR                  TO ZMDP-FUNCTION                          160916 
 1949.00            PERFORM M100-ZMDPIO                                                   160916 
 1950.00       *                                                                          160407 
 1951.00            .                                                                     160916 
 1952.00        5190-EXIT.                                                                160407 
 1953.00             EXIT.                                                                160407 
 1954.00       /                                                                          160407 
 1955.00        5200-CREATE-POLICY-DETAILS SECTION.                                       160407 
 1956.00       ************************************                                       160407 
 1957.00        5210-START.                                                               160407 
 1958.00       *                                                                          160407 
 1959.00       * Initialize ZMDP & ZNGP records prior to writing new records              160407 
 1960.00       *                                                                          160407 
 1961.00            INITIALIZE                     ZMDP-PARAMS                            160407 
 1962.00                                           ZNGP-PARAMS                            160916 
 1963.00       *                                                                          160407 
 1964.00       * Setup Policy no                                                          160407 
 1965.00       *                                                                          160407 
 1966.00            MOVE WSAA-WORK-CHDRNUM      TO ZMDP-ZPOLICY                           160407 
 1967.00                                           ZNGP-ZPOLICY                           160916 
 1968.00       *                                                                          160407 
 1969.00       * Setup Main Life CCS no with leading zeroes.                              160407 
 1970.00       * NOTE: ZLFCODE only exists for ZNGP                                       160407 
 1971.00       *                                                                          160407 
 1972.00            MOVE WSAA-MAIN-CCSNO        TO ZNGP-ZLFCODE                           160916 
 1973.00       *                                                                          160407 
 1974.00       * Setup Main Life Client name                                              160407 
 1975.00       *                                                                          160407 
 1976.00            MOVE CLNT-SURNAME           TO WSAA-CLIENT-SURNAME                    160916 
 1977.00            MOVE CLNT-GIVNAME           TO WSAA-CLIENT-GIVNAME                    160916 
 1978.00            MOVE WSAA-CLIENT-NAME       TO ZMDP-CLNTNAME                          160407 
 1979.00                                           ZNGP-CLNTNAME                          160916 
 1980.00       *                                                                          160407 
 1981.00       * Setup policy type (Always I)                                             160407 
 1982.00       *                                                                          160407 
 1983.00            MOVE WSCC-I                 TO ZMDP-ZPOLTYP                           160407 
 1984.00                                           ZNGP-ZPOLTYP                           160916 
 1985.00       *                                                                          160407 
 1986.00       * Setup paid to date / effective date (Always occdate)                     160407 
 1987.00       *                                                                          160407 
 1988.00            MOVE CHDRINP-OCCDATE        TO WSAA-DATCON1-DATE                      160916 
 1989.00            MOVE SPACES                 TO WSAA-DESC-DATE                         160916 
 1990.00            MOVE '5200-OCCD'            TO WSAA-DESC-DATE                         160916 
 1991.00            PERFORM 16000-CONVERT-DATE.                                           160407 
 1992.00            MOVE DTC1-EXT-DATE          TO ZMDP-ZPTDATE                           160407 
 1993.00                                           ZNGP-ZPTDATE                           160407 
 1994.00                                           ZMDP-EFFCDTE                           160407 
 1995.00                                           ZNGP-EFFCDTE                           160916 
 1996.00       *                                                                          160407 
 1997.00       * Setup expiry date (Risk Commencemet Date + 1 year)                       160407 
 1998.00       *                                                                          160407 
 1999.00            MOVE CHDRINP-OCCDATE        TO DTC2-INT-DATE-1                        160916 
 2000.00            MOVE FREQ-YRLY              TO DTC2-FREQUENCY                         160916 
 2001.00            MOVE WSCC-1                 TO DTC2-FREQ-FACTOR                       160916 
 2002.00            CALL 'DATCON2'           USING DTC2-DATCON2-REC                       160916 
 2003.00            IF  DTC2-STATUZ          NOT = O-K                                    160407 
 2004.00                MOVE DTC2-DATCON2-REC   TO SYSR-PARAMS                            160407 
 2005.00                MOVE DTC2-STATUZ        TO SYSR-STATUZ                            160407 
 2006.00                PERFORM 600-FATAL-ERROR                                           160407 
 2007.00            END-IF                                                                160916 
 2008.00            MOVE DTC2-INT-DATE-2        TO WSAA-DATCON1-DATE                      160916 
 2009.00            MOVE SPACES                 TO WSAA-DESC-DATE                         160916 
 2010.00            MOVE '5200-ANNI'            TO WSAA-DESC-DATE                         160916 
 2011.00            PERFORM 16000-CONVERT-DATE                                            160916 
 2012.00            MOVE DTC1-EXT-DATE          TO ZMDP-ZEXPDATE                          160407 
 2013.00                                           ZNGP-ZEXPDATE                          160916 
 2014.00       *                                                                          160407 
 2015.00       * Setup Application Inception date                                         160407 
 2016.00       *                                                                          160407 
 2017.00            MOVE ZCHD-ZAPPSGN           TO WSAA-DATCON1-DATE                      160916 
 2018.00            MOVE SPACES                 TO WSAA-DESC-DATE                         160916 
 2019.00            MOVE '5200-ZAPPS'           TO WSAA-DESC-DATE                         160916 
 2020.00            PERFORM 16000-CONVERT-DATE                                            160916 
 2021.00            MOVE DTC1-EXT-DATE          TO ZMDP-INCDTE                            160407 
 2022.00                                           ZNGP-INCDTE                            160916 
 2023.00       *                                                                          160407 
 2024.00       * Setup Contract Agency Code (Always spaces)                               160407 
 2025.00       *                                                                          160407 
 2026.00            MOVE SPACES                 TO ZMDP-ZMDAGY                            160407 
 2027.00                                           ZNGP-ZMDAGY                            160916 
 2028.00       *                                                                          160407 
 2029.00       * Setup Contract Agent no                                                  160407 
 2030.00       *                                                                          160407 
 2031.00            MOVE ZAGPCTO-AGNTNUM        TO WSAA-AGNTNUM                           160916 
 2032.00            MOVE WSAA-AGNTNUM-3         TO WSAA-AGENT-NUM                         160916 
 2033.00            IF  WSAA-AGNTNUM-3           = WSCC-3-ZEROES                          160407 
 2034.00                MOVE WSCC-001           TO WSAA-AGNTNUM-3                         160407 
 2035.00            END-IF                                                                160916 
 2036.00            MOVE WSAA-AGNTNUM-3         TO ZMDP-ZMDAGNT                           160407 
 2037.00                                           ZNGP-ZMDAGNT                           160916 
 2038.00       *                                                                          160407 
 2039.00       * Setup Product Code from T5Z48. If space default 1                        160407 
 2040.00       *                                                                          160407 
 2041.00            IF  WSAA-LIFCNUM-PRODN(IX)   = SPACES                                 160407 
 2042.00                MOVE WSCC-1             TO ZMDP-PRODN                             160407 
 2043.00                                           ZNGP-PRODN                             160407 
 2044.00            ELSE                                                                  160407 
 2045.00                MOVE WSAA-LIFCNUM-PRODN(IX)                                       160407 
 2046.00                                        TO ZMDP-PRODN                             160407 
 2047.00                                           ZNGP-PRODN                             160407 
 2048.00            END-IF                                                                160916 
 2049.00       *                                                                          160407 
 2050.00       * Setup Contract Payplan (Always spaces)                                   160407 
 2051.00       *                                                                          160407 
 2052.00            MOVE SPACES                 TO ZMDP-PAYPLAN                           160407 
 2053.00                                           ZNGP-PAYPLAN                           160916 
 2054.00       *                                                                          160407 
 2055.00       * Setup Security Entity no                                                 160407 
 2056.00       *                                                                          160407 
 2057.00            MOVE CLNT-SECUITYNO         TO ZMDP-JENTID                            160916 
 2058.00       *                                                                          160407 
 2059.00       * Setup Address Details                                                    160407 
 2060.00       *                                                                          160407 
 2061.00            STRING CLNT-CLTADDR01       DELIMITED BY SIZE                         160407 
 2062.00                   CLNT-CLTADDR02(1:10) DELIMITED BY SIZE                         160407 
 2063.00                   CLNT-CLTADDR03(1:20) DELIMITED BY SIZE                         160407 
 2064.00                   CLNT-CLTADDR04(1:20) DELIMITED BY SIZE                         160407 
 2065.00                                      INTO ZMDP-ZMDADR                            160916 
 2066.00            MOVE ZMDP-ZMDADR            TO ZNGP-ZMDADR                            160916 
 2067.00       *                                                                          160407 
 2068.00       * Setup Address Postcode                                                   160407 
 2069.00       *                                                                          160407 
 2070.00            MOVE CLNT-CLTPCODE          TO ZMDP-ZMDZIP                            160407 
 2071.00                                           ZNGP-ZMDZIP                            160916 
 2072.00       *                                                                          160407 
 2073.00       * Setup Fax details                                                        160407 
 2074.00       *                                                                          160407 
 2075.00            MOVE SPACES                 TO ZMDP-ZMDFAX                            160407 
 2076.00                                           ZNGP-ZMDFAX                            160916 
 2077.00       *                                                                          160407 
 2078.00       * Setup Phone 1 details                                                    160407 
 2079.00       *                                                                          160407 
 2080.00            MOVE CLNT-CLTPHONE01        TO ZMDP-ZMDPHA                            160407 
 2081.00                                           ZNGP-ZMDPHA                            160916 
 2082.00       *                                                                          160407 
 2083.00       * Setup Phone 2 details                                                    160407 
 2084.00       *                                                                          160407 
 2085.00            MOVE CLNT-CLTPHONE02        TO ZMDP-ZMDPHB                            160407 
 2086.00                                           ZNGP-ZMDPHB                            160916 
 2087.00       *                                                                          160407 
 2088.00       * Setup Tax no                                                             160407 
 2089.00       *                                                                          160407 
 2090.00            IF  CLNT-JTAXNUM             = SPACES                                 160407 
 2091.00                MOVE SPACES             TO ZMDP-ZMDID                             160407 
 2092.00                                           ZNGP-ZMDID                             160407 
 2093.00            ELSE                                                                  160407 
 2094.00                MOVE CLNT-JTAXNUM       TO ZMDP-ZMDID                             160407 
 2095.00                                           ZNGP-ZMDID                             160407 
 2096.00            END-IF                                                                160916 
 2097.00       *                                                                          160407 
 2098.00       * Setup Group no (Always spaces)                                           160407 
 2099.00       *                                                                          160407 
 2100.00            MOVE SPACES                 TO ZMDP-ZGRPNUM                           160407 
 2101.00                                           ZNGP-ZGRPNUM                           160916 
 2102.00       *                                                                          160407 
 2103.00       * Setup transaction type                                                   160407 
 2104.00       * ======================                                                   160407 
 2105.00       * 01 = Initial Policy                                                      160407 
 2106.00       * 10 = Policy Cancellation                                                 160407 
 2107.00       * 20 = Policy Reactivation                                                 160407 
 2108.00       * 30 = Policy Correction                                                   160407 
 2109.00       *                                                                          160407 
 2110.00       * In this case we have to check the case that we have                      160407 
 2111.00       * AFI in one contract and the MEDNET has already the contract              160407 
 2112.00       * with Status 01(Initial).Then the contract is been reissue again          160407 
 2113.00       * so we have to send the contract again in MEDNET with status              160407 
 2114.00       * 02(Modification).                                                        160407 
 2115.00       *                                                                          160407 
 2116.00       * Tran Type 01 - Policy inforce                                            160407 
 2117.00       *                                                                          160407 
 2118.00            IF  CONTRACT-INFORCE                                                  160407 
 2119.00                MOVE SPACES                 TO WSAA-TRAN-TYP                      160916 
 2120.00                MOVE WSCC-NEW               TO WSAA-TRAN-TYP                      160916 
 2121.00                PERFORM 17000-READ-T9Z20                                          160916 
 2122.00                MOVE T9Z20-ZTRNTYP(1)       TO ZMDP-ZTRNTYP                       160916 
 2123.00                                               ZNGP-ZTRNTYP                       160916 
 2124.00       ***      MOVE WSCC-01            TO ZMDP-ZTRNTYP                           160916 
 2125.00       ***                                 ZNGP-ZTRNTYP                           160916 
 2126.00            END-IF                                                                160916 
 2127.00       *                                                                          160407 
 2128.00       * Tran type 10 - Policy not inforce (LA,SU,CF,PU)                          160407 
 2129.00       *                                                                          160407 
 2130.00            IF  NOT CONTRACT-INFORCE                                              160411 
 2131.00                MOVE SPACES             TO WSAA-TRAN-TYP                          160916 
 2132.00                MOVE WSCC-CANCL         TO WSAA-TRAN-TYP                          160916 
 2133.00                PERFORM 17000-READ-T9Z20                                          160916 
 2134.00                MOVE T9Z20-ZTRNTYP(1)   TO ZMDP-ZTRNTYP                           160916 
 2135.00                                           ZNGP-ZTRNTYP                           160916 
 2136.00       ***      MOVE WSCC-10            TO ZMDP-ZTRNTYP                           160916 
 2137.00       ***                                 ZNGP-ZTRNTYP                           160916 
 2138.00            END-IF                                                                160916 
 2139.00       *                                                                          160407 
 2140.00       * Tran type 30 - Modification (ZNGP exists & policy inforce)               160407 
 2141.00       *                                                                          160407 
 2142.00            IF  ZNGP-FOUND                                                        160407 
 2143.00            AND CONTRACT-INFORCE                                                  160407 
 2144.00                MOVE SPACES             TO WSAA-TRAN-TYP                          160916 
 2145.00                MOVE WSCC-MODIF         TO WSAA-TRAN-TYP                          160916 
 2146.00                PERFORM 17000-READ-T9Z20                                          160916 
 2147.00                MOVE T9Z20-ZTRNTYP(1)   TO ZMDP-ZTRNTYP                           160916 
 2148.00                                           ZNGP-ZTRNTYP                           160916 
 2149.00       ***      MOVE WSCC-30            TO ZMDP-ZTRNTYP                           160916 
 2150.00       ***                                 ZNGP-ZTRNTYP                           160916 
 2151.00                MOVE SPACES             TO ZMDP-EFFCDTE                           160407 
 2152.00                                           ZNGP-EFFCDTE                           160407 
 2153.00                MOVE SPACES             TO ZMDP-ZPTDATE                           160407 
 2154.00                                           ZNGP-ZPTDATE                           160407 
 2155.00                MOVE SPACES             TO ZMDP-ZEXPDATE                          160407 
 2156.00                                           ZNGP-ZEXPDATE                          160407 
 2157.00                MOVE SPACES             TO ZMDP-INCDTE                            160407 
 2158.00                                           ZNGP-INCDTE                            160407 
 2159.00            END-IF                                                                160916 
 2160.00       *                                                                          160407 
 2161.00       * Policy Reactivation                                                      160412 
 2162.00       * ===================                                                      160412 
 2163.00       * If original ZNGP had tran type 10 (Policy Cancelled) and the             160407 
 2164.00       * policy status code is now inforce then we setup the policy               160412 
 2165.00       * detail trans type to 20 (Policy Reactivation)                            160412 
 2166.00       *                                                                          160511 
 2167.00       *                                                                          160407 
 2168.00            IF  ZNGP-FOUND                                                        160407 
 2169.00            AND WSAA-ZNGP-ZTRNTYP        = WSCC-10                                160407 
 2170.00            AND CONTRACT-INFORCE                                                  160407 
 2171.00       *****************************************************************          160511 
 2172.00       * NOTE - Until further notice we use 01 for Policy Reactivation            160511 
 2173.00       *****************************************************************          160511 
 2174.00       ****     MOVE WSCC-20            TO ZMDP-ZTRNTYP                           160511 
 2175.00                MOVE SPACES             TO WSAA-TRAN-TYP                          160916 
 2176.00                MOVE WSCC-REACT         TO WSAA-TRAN-TYP                          160916 
 2177.00                PERFORM 17000-READ-T9Z20                                          160916 
 2178.00                MOVE T9Z20-ZTRNTYP(1)   TO ZMDP-ZTRNTYP                           160916 
 2179.00                                           ZNGP-ZTRNTYP                           160916 
 2180.00       ***      MOVE WSCC-01            TO ZMDP-ZTRNTYP                           160916 
 2181.00       ***                                 ZNGP-ZTRNTYP                           160916 
 2182.00            END-IF                                                                160916 
 2183.00       *                                                                          160407 
 2184.00       * Setup sequence no (always increase by 1)                                 160407 
 2185.00       *                                                                          160407 
 2186.00            ADD WSCC-1                  TO WSAA-SEQNUM                            160407 
 2187.00            PERFORM 15000-DELETE-SEQ-ZEROES                                       160407 
 2188.00            MOVE WSAA-SEQ-NUMBERS       TO ZMDP-ZTRNNUM                           160407 
 2189.00                                           ZNGP-ZTRNNUM                           160916 
 2190.00       *                                                                          160407 
 2191.00       * Setup modification date                                                  160407 
 2192.00       * - Default to spaces                                                      160407 
 2193.00       * - If not initial policy set to PTRN transaction date                     160407 
 2194.00       *                                                                          160407 
 2195.00            MOVE SPACES                 TO ZMDP-ZMODDTE                           160407 
 2196.00                                           ZNGP-ZMODDTE                           160916 
 2197.00       *                                                                          160407 
 2198.00       * If tran type not 01 (ie Not Initial Policy)                              160407 
 2199.00       *                                                                          160407 
 2200.00            IF ZMDP-ZTRNTYP          NOT = WSCC-01                                160407 
 2201.00               MOVE BSSC-EFFECTIVE-DATE TO WSAA-DATCON1-DATE                      160412 
 2202.00               MOVE SPACES              TO WSAA-DESC-DATE                         160407 
 2203.00               MOVE '5200-ZPTREFC'      TO WSAA-DESC-DATE                         160407 
 2204.00               PERFORM 16000-CONVERT-DATE                                         160407 
 2205.00               MOVE DTC1-EXT-DATE       TO ZMDP-ZMODDTE                           160407 
 2206.00                                           ZNGP-ZMODDTE                           160407 
 2207.00            END-IF                                                                160916 
 2208.00       *                                                                          160407 
 2209.00       * If special processing (ie T514 Lapse or T557 Comp Add)                   160407 
 2210.00       * then modification date will be the PTRN effdate                          160407 
 2211.00       *                                                                          160407 
 2212.00            IF  TRAN-SPECIAL                                                      160407 
 2213.00                MOVE WSAA-WORK-EFFDATE  TO WSAA-DATCON1-DATE                      160412 
 2214.00                MOVE SPACES             TO WSAA-DESC-DATE                         160407 
 2215.00                MOVE '5200-ZPTR-EFF'    TO WSAA-DESC-DATE                         160407 
 2216.00                PERFORM 16000-CONVERT-DATE                                        160407 
 2217.00                MOVE DTC1-EXT-DATE      TO ZMDP-ZMODDTE                           160407 
 2218.00                                           ZNGP-ZMODDTE                           160407 
 2219.00            END-IF                                                                160916 
 2220.00       *                                                                          160407 
 2221.00       * Setup cancellation date                                                  160407 
 2222.00       * - Default to spaces                                                      160407 
 2223.00       * - If policy not inforce set to PTRN transaction date                     160407 
 2224.00       *                                                                          160407 
 2225.00            MOVE SPACES                 TO ZMDP-ZCANDTE                           160407 
 2226.00                                           ZNGP-ZCANDTE                           160916 
 2227.00       *                                                                          160407 
 2228.00            IF ZMDP-ZTRNTYP              = WSCC-10                                160407 
 2229.00               MOVE WSAA-TRANS-DATE-NEW TO WSAA-DATCON1-DATE                      160412 
 2230.00               MOVE SPACES              TO WSAA-DESC-DATE                         160407 
 2231.00               MOVE '5200-ZPTREFC'      TO WSAA-DESC-DATE                         160407 
 2232.00               PERFORM 16000-CONVERT-DATE                                         160407 
 2233.00               MOVE DTC1-EXT-DATE       TO ZMDP-ZCANDTE                           160407 
 2234.00                                           ZNGP-ZCANDTE                           160407 
 2235.00            END-IF                                                                160916 
 2236.00       *                                                                          160407 
 2237.00       * Setup cancellation type (Always spaces)                                  160407 
 2238.00       *                                                                          160407 
 2239.00            MOVE SPACES                 TO ZMDC-ZCANTYP                           160407 
 2240.00                                           ZNGC-ZCANTYP                           160916 
 2241.00       *                                                                          160407 
 2242.00       * Setup container type (Always spaces)                                     160407 
 2243.00       *                                                                          160407 
 2244.00            MOVE SPACES                 TO ZMDC-CONTTYPE                          160407 
 2245.00                                           ZNGC-CONTTYPE                          160916 
 2246.00       *                                                                          160407 
 2247.00       * Setup Bank account no (Always spaces)                                    160407 
 2248.00       *                                                                          160407 
 2249.00            MOVE SPACES                 TO ZMDC-ZBNKNUM                           160407 
 2250.00                                           ZNGC-ZBNKNUM                           160916 
 2251.00       *                                                                          160407 
 2252.00       * Setup Country (always GR)                                                160407 
 2253.00       *                                                                          160407 
 2254.00            MOVE WSCC-GR                TO ZMDP-ZCONTR                            160407 
 2255.00                                           ZNGP-ZCONTR                            160916 
 2256.00       *                                                                          160407 
 2257.00       * Setup Account Holder                                                     160407 
 2258.00       *                                                                          160407 
 2259.00            MOVE WSAA-CLIENT-NAME       TO ZMDP-ZMDACCH                           160407 
 2260.00                                           ZNGP-ZMDACCH                           160916 
 2261.00       *                                                                          160407 
 2262.00       * Setup City (Always spaces)                                               160407 
 2263.00       *                                                                          160407 
 2264.00            MOVE SPACES                 TO ZMDP-ZCITY                             160407 
 2265.00                                           ZNGP-ZCITY.                            160407 
 2266.00       *                                                                          160407 
 2267.00       * Setup Classification (Always spaces)                                     160407 
 2268.00       *                                                                          160407 
 2269.00            MOVE SPACES                 TO ZMDP-ZCLASS                            160407 
 2270.00                                           ZNGP-ZCLASS                            160916 
 2271.00       *                                                                          160407 
 2272.00       * Setup way of payment (Always spaces)                                     160407 
 2273.00       *                                                                          160407 
 2274.00            MOVE SPACES                 TO ZMDP-ZPAYMENT                          160407 
 2275.00                                           ZNGP-ZPAYMENT                          160916 
 2276.00       *                                                                          160407 
 2277.00       * Setup Checkbox Subfile Selection (Always spaces)                         160407 
 2278.00       *                                                                          160407 
 2279.00            MOVE SPACES                 TO ZMDP-JLBL                              160407 
 2280.00                                           ZNGP-JLBL                              160916 
 2281.00       *                                                                          160407 
 2282.00       * Write the valid record in ZMDP file                                      160407 
 2283.00       *                                                                          160407 
 2284.00            MOVE WRITR                  TO ZMDP-FUNCTION                          160916 
 2285.00            PERFORM M100-ZMDPIO                                                   160916 
 2286.00       *                                                                          160407 
 2287.00       * Process for control totals,for Initial,modify and                        160407 
 2288.00       * canceled records for ZMDP file.                                          160407 
 2289.00       *                                                                          160407 
 2290.00       * CT01 - Total ZMDP records written                                        160408 
 2291.00       *                                                                          160408 
 2292.00            MOVE CT01                   TO CONT-TOTNO                             160916 
 2293.00            MOVE 1                      TO CONT-TOTVAL                            160916 
 2294.00            PERFORM 001-CALL-CONTOT                                               160916 
 2295.00       *                                                                          160408 
 2296.00       * CT04 - Total ZMDP initial records written                                160408 
 2297.00       *                                                                          160407 
 2298.00            IF  ZMDP-ZTRNTYP             = WSCC-01                                160407 
 2299.00                MOVE CT04               TO CONT-TOTNO                             160407 
 2300.00                MOVE 1                  TO CONT-TOTVAL                            160407 
 2301.00                PERFORM 001-CALL-CONTOT                                           160407 
 2302.00            END-IF                                                                160916 
 2303.00       *                                                                          160407 
 2304.00       * CT05 - Total ZMDP modify records written                                 160408 
 2305.00       *                                                                          160408 
 2306.00            IF  ZMDP-ZTRNTYP             = WSCC-20                                160407 
 2307.00            OR  ZMDP-ZTRNTYP             = WSCC-30                                160407 
 2308.00                MOVE CT05               TO CONT-TOTNO                             160407 
 2309.00                MOVE 1                  TO CONT-TOTVAL                            160407 
 2310.00                PERFORM 001-CALL-CONTOT                                           160407 
 2311.00            END-IF                                                                160916 
 2312.00       *                                                                          160407 
 2313.00       * CT06 - Total ZMDP cancel records written                                 160408 
 2314.00       *                                                                          160408 
 2315.00            IF  ZMDP-ZTRNTYP             = WSCC-10                                160407 
 2316.00                MOVE CT06               TO CONT-TOTNO                             160407 
 2317.00                MOVE 1                  TO CONT-TOTVAL                            160407 
 2318.00                PERFORM 001-CALL-CONTOT                                           160407 
 2319.00            END-IF                                                                160916 
 2320.00       *                                                                          160407 
 2321.00       * Write the valid record in ZNGP file                                      160407 
 2322.00       *                                                                          160407 
 2323.00            MOVE WRITR                  TO ZNGP-FUNCTION                          160916 
 2324.00            PERFORM N100-ZNGPIO                                                   160916 
 2325.00       *                                                                          160407 
 2326.00            .                                                                     160916 
 2327.00        5290-EXIT.                                                                160407 
 2328.00            EXIT.                                                                 160407 
 2329.00       /                                                                          160407 
 2330.00        5300-DELETE-ZNGC SECTION.                                                 160407 
 2331.00       **************************                                                 160407 
 2332.00        5310-START.                                                               160407 
 2333.00       *                                                                          160407 
 2334.00            PERFORM N200-ZNGCIO                                                   160916 
 2335.00       *                                                                          160407 
 2336.00            IF  ZNGC-STATUZ              = ENDP                                   160407 
 2337.00            OR  ZNGC-ZPOLICY(1:8)    NOT = WSAA-WORK-CHDRNUM                      160411 
 2338.00                MOVE ENDP               TO ZNGC-STATUZ                            160407 
 2339.00                GO TO 5390-EXIT                                                   160407 
 2340.00            END-IF                                                                160916 
 2341.00       *                                                                          160407 
 2342.00       * If we reach this point then we we have ZNGC records already              160407 
 2343.00       * for this contract so set relevant ind to true                            160407 
 2344.00       *                                                                          160407 
 2345.00            SET ZNGC-FOUND              TO TRUE                                   160916 
 2346.00       *                                                                          160407 
 2347.00       * Store current ZNGC life CCS no in w/s array                              160407 
 2348.00       *                                                                          160407 
 2349.00            ADD  1                      TO IZ                                     160916 
 2350.00            MOVE ZNGC-ZLFCODE(1:8)      TO WSAA-ZNGC-ZLFCODE(IZ)                  160916 
 2351.00            MOVE ZNGC-JREGNO(1:8)       TO WSAA-ZNGC-JREGNO(IZ)                   160916 
 2352.00       *                                                                          160407 
 2353.00       * Check if the current ZNGC life member still exists as                    160407 
 2354.00       * a valid life for the contract                                            160407 
 2355.00       *                                                                          160407 
 2356.00            SET MEMBER-NOT-FOUND        TO TRUE                                   160916 
 2357.00       *                                                                          160407 
 2358.00            PERFORM VARYING IX        FROM 1 BY 1                                 160407 
 2359.00              UNTIL IX                   > WSCC-MAX-LIVES                         160407 
 2360.00                 OR WSAA-LIFCNUM(IX)     = SPACES                                 160407 
 2361.00                 OR MEMBER-FOUND                                                  160407 
 2362.00               IF  ZNGC-ZLFCODE(1:8)     = WSAA-LIFCNUM-CCSNOCL(IX)               160407 
 2363.00                   SET MEMBER-FOUND     TO TRUE                                   160407 
 2364.00               END-IF                                                             160407 
 2365.00            END-PERFORM                                                           160916 
 2366.00       *                                                                          160407 
 2367.00       * If the current ZNGC member no longer exists as a valid life              160407 
 2368.00       * for the contract (ie lapsed coverages) then we need to                   160407 
 2369.00       * register that this member has been cancelled                             160407 
 2370.00       *                                                                          160407 
 2371.00            IF  CONTRACT-INFORCE                                                  160407 
 2372.00            AND MEMBER-NOT-FOUND                                                  160407 
 2373.00                PERFORM 5400-CRT-CANCELLATION-ZMDC                                160407 
 2374.00            END-IF                                                                160916 
 2375.00       *                                                                          160407 
 2376.00       * Delete ZNGC record                                                       160407 
 2377.00       *                                                                          160407 
 2378.00            MOVE DELET                  TO ZNGC-FUNCTION                          160916 
 2379.00            PERFORM N200-ZNGCIO                                                   160916 
 2380.00       *                                                                          160407 
 2381.00       * Setup next read of ZNGC                                                  160407 
 2382.00       *                                                                          160407 
 2383.00            MOVE NEXTR                  TO ZNGC-FUNCTION                          160916 
 2384.00       *                                                                          160407 
 2385.00            .                                                                     160916 
 2386.00        5390-EXIT.                                                                160407 
 2387.00             EXIT.                                                                160407 
 2388.00       /                                                                          160407 
 2389.00        5400-CRT-CANCELLATION-ZMDC SECTION.                                       160407 
 2390.00       ************************************                                       160407 
 2391.00        5410-START.                                                               160407 
 2392.00       *                                                                          160407 
 2393.00       * Initialize ZMDC record                                                   160407 
 2394.00       *                                                                          160407 
 2395.00            INITIALIZE                     ZMDC-PARAMS                            160916 
 2396.00       *                                                                          160407 
 2397.00       * Setup fields from current ZNGC                                           160407 
 2398.00       *                                                                          160407 
 2399.00            MOVE ZNGC-ZPOLICY           TO ZMDC-ZPOLICY                           160916 
 2400.00            MOVE ZNGC-ZLFCODE           TO ZMDC-ZLFCODE                           160916 
 2401.00            MOVE ZNGC-ZFIRSTNM          TO ZMDC-ZFIRSTNM                          160916 
 2402.00            MOVE ZNGC-ZLASTNM           TO ZMDC-ZLASTNM                           160916 
 2403.00            MOVE ZNGC-JENTID            TO ZMDC-JENTID                            160916 
 2404.00            MOVE ZNGC-ZBRTHDTE          TO ZMDC-ZBRTHDTE                          160916 
 2405.00            MOVE ZNGC-ZMDID             TO ZMDC-ZMDID                             160916 
 2406.00            MOVE ZNGC-ZPTDATE           TO ZMDC-ZPTDATE                           160916 
 2407.00            MOVE ZNGC-EFFCDTE           TO ZMDC-EFFCDTE                           160916 
 2408.00            MOVE ZNGC-ZMDSEX            TO ZMDC-ZMDSEX                            160916 
 2409.00            MOVE ZNGC-USERX             TO ZMDC-USERX                             160916 
 2410.00            MOVE ZNGC-ZROOMCL           TO ZMDC-ZROOMCL                           160916 
 2411.00            MOVE ZNGC-JREGNO            TO ZMDC-JREGNO                            160916 
 2412.00            MOVE ZNGC-JXREFNUM          TO ZMDC-JXREFNUM                          160916 
 2413.00            MOVE ZNGC-ZPACKCOD          TO ZMDC-ZPACKCOD                          160916 
 2414.00            MOVE ZNGC-ZMARSTAT          TO ZMDC-ZMARSTAT                          160916 
 2415.00            MOVE ZNGC-ZMDADR            TO ZMDC-ZMDADR                            160916 
 2416.00            MOVE ZNGC-ZMDZIP            TO ZMDC-ZMDZIP                            160916 
 2417.00            MOVE ZNGC-ZMDFAX            TO ZMDC-ZMDFAX                            160916 
 2418.00            MOVE ZNGC-ZMDPHA            TO ZMDC-ZMDPHA                            160916 
 2419.00            MOVE ZNGC-ZMDPHB            TO ZMDC-ZMDPHB                            160916 
 2420.00       *                                                                          160407 
 2421.00       * 40 = Member Cancellation                                                 160407 
 2422.00       *                                                                          160407 
 2423.00            MOVE SPACES             TO WSAA-TRAN-TYP                              160916 
 2424.00            MOVE WSCC-CANCL         TO WSAA-TRAN-TYP                              160916 
 2425.00            PERFORM 17000-READ-T9Z20                                              160916 
 2426.00            MOVE T9Z20-ZTRNTYP(2)   TO ZMDC-ZTRNTYP                               160916 
 2427.00                                                                                  160916 
 2428.00       ***  MOVE WSCC-40                TO ZMDC-ZTRNTYP.                          160916 
 2429.00       *                                                                          160407 
 2430.00       * Setup sequence no                                                        160407 
 2431.00       *                                                                          160407 
 2432.00            ADD WSCC-1                  TO WSAA-SEQNUM                            160407 
 2433.00            PERFORM 15000-DELETE-SEQ-ZEROES                                       160916 
 2434.00            MOVE WSAA-SEQ-NUMBERS       TO ZMDC-ZTRNNUM                           160916 
 2435.00       *                                                                          160414 
 2436.00       * Setup modification date                                                  160414 
 2437.00       *                                                                          160414 
 2438.00            MOVE BSSC-EFFECTIVE-DATE    TO WSAA-DATCON1-DATE                      160916 
 2439.00            MOVE SPACES                 TO WSAA-DESC-DATE                         160916 
 2440.00            MOVE '5400-BSSC'            TO WSAA-DESC-DATE                         160916 
 2441.00            PERFORM 16000-CONVERT-DATE                                            160916 
 2442.00            MOVE DTC1-EXT-DATE          TO ZMDC-ZMODDTE                           160916 
 2443.00       *                                                                          160414 
 2444.00       * Setup cancellation date                                                  160414 
 2445.00       *                                                                          160414 
 2446.00            MOVE WSAA-TRANS-DATE-NEW    TO WSAA-DATCON1-DATE                      160916 
 2447.00            MOVE SPACES                 TO WSAA-DESC-DATE                         160916 
 2448.00            MOVE '5400-ZPTREFC'         TO WSAA-DESC-DATE                         160916 
 2449.00            PERFORM 16000-CONVERT-DATE                                            160916 
 2450.00            MOVE DTC1-EXT-DATE          TO ZMDC-ZCANDTE                           160916 
 2451.00       *                                                                          160414 
 2452.00       * If special processing (ie T514 Lapse or T557 Comp Add)                   160414 
 2453.00       * then modification/cancel dates will be the PTRN effdate                  160414 
 2454.00       *                                                                          160414 
 2455.00            IF  TRAN-SPECIAL                                                      160414 
 2456.00                MOVE WSAA-WORK-EFFDATE  TO WSAA-DATCON1-DATE                      160414 
 2457.00                MOVE SPACES             TO WSAA-DESC-DATE                         160414 
 2458.00                MOVE '5400-ZPTR-EFF'    TO WSAA-DESC-DATE                         160414 
 2459.00                PERFORM 16000-CONVERT-DATE                                        160414 
 2460.00                MOVE DTC1-EXT-DATE      TO ZMDC-ZMODDTE                           160414 
 2461.00                                           ZMDC-ZCANDTE                           160414 
 2462.00            END-IF                                                                160916 
 2463.00       *                                                                          160407 
 2464.00       * Setup remaining fields from ZNGC                                         160414 
 2465.00       *                                                                          160407 
 2466.00            MOVE ZNGC-ZCANTYP           TO ZMDC-ZCANTYP                           160916 
 2467.00            MOVE ZNGC-JFTNAME           TO ZMDC-JFTNAME                           160916 
 2468.00            MOVE ZNGC-ZINTFNME          TO ZMDC-ZINTFNME                          160916 
 2469.00            MOVE ZNGC-ZINTMNME          TO ZMDC-ZINTMNME                          160916 
 2470.00            MOVE ZNGC-ZINTLNME          TO ZMDC-ZINTLNME                          160916 
 2471.00            MOVE ZNGC-ZMEMBNUM          TO ZMDC-ZMEMBNUM                          160916 
 2472.00            MOVE ZNGC-ZMDNATIO          TO ZMDC-ZMDNATIO                          160916 
 2473.00            MOVE ZNGC-JDFTVAL           TO ZMDC-JDFTVAL                           160916 
 2474.00            MOVE ZNGC-ZMDRES            TO ZMDC-ZMDRES                            160916 
 2475.00            MOVE ZNGC-CONTTYPE          TO ZMDC-CONTTYPE                          160916 
 2476.00            MOVE ZNGC-ZBNKNUM           TO ZMDC-ZBNKNUM                           160916 
 2477.00            MOVE ZNGC-ZMDACCH           TO ZMDC-ZMDACCH                           160916 
 2478.00            MOVE ZNGC-ZCONTR            TO ZMDC-ZCONTR                            160916 
 2479.00            MOVE ZNGC-ZCITY             TO ZMDC-ZCITY                             160916 
 2480.00            MOVE ZNGC-JLBL              TO ZMDC-JLBL                              160916 
 2481.00            MOVE ZNGC-ZCDEANNO          TO ZMDC-ZCDEANNO                          160916 
 2482.00            MOVE ZNGC-ENTYDESC          TO ZMDC-ENTYDESC                          160916 
 2483.00            MOVE ZNGC-ZMDIBAN           TO ZMDC-ZMDIBAN                           160916 
 2484.00            MOVE ZNGC-ZLEXTREF          TO ZMDC-ZLEXTREF                          160916 
 2485.00            MOVE ZNGC-ZLEXTPR           TO ZMDC-ZLEXTPR                           160916 
 2486.00            MOVE ZNGC-ZCONFDAT          TO ZMDC-ZCONFDAT                          160916 
 2487.00            MOVE ZNGC-ZBANKC            TO ZMDC-ZBANKC                            160916 
 2488.00       *                                                                          160407 
 2489.00       * Write the valid record in ZMDC file                                      160407 
 2490.00       *                                                                          160407 
 2491.00            MOVE WRITR                  TO ZMDC-FUNCTION                          160916 
 2492.00            PERFORM M200-ZMDCIO                                                   160916 
 2493.00       *                                                                          160407 
 2494.00            .                                                                     160916 
 2495.00        5490-EXIT.                                                                160407 
 2496.00             EXIT.                                                                160407 
 2497.00       /                                                                          160407 
 2498.00        5500-DELETE-ZNGN SECTION.                                                 160407 
 2499.00       **************************                                                 160407 
 2500.00        5510-START.                                                               160407 
 2501.00       *                                                                          160407 
 2502.00            PERFORM N300-ZNGNIO                                                   160916 
 2503.00       *                                                                          160407 
 2504.00       * If eof or change of key then exit loop processing                        160407 
 2505.00       *                                                                          160407 
 2506.00            IF  ZNGN-STATUZ              = ENDP                                   160407 
 2507.00            OR  ZNGN-ZPOLICY(1:8)    NOT = WSAA-WORK-CHDRNUM                      160411 
 2508.00                MOVE ENDP               TO ZNGN-STATUZ                            160407 
 2509.00                GO TO 5590-EXIT                                                   160407 
 2510.00            END-IF                                                                160916 
 2511.00                                                                         <ATHC84> 180801 
 2512.00       **** SET FOUND-ZNGN              TO TRUE                          <ATHC84> 180806 
 2513.00            ADD  WSCC-1                 TO ZNGN-I                        <ATHC84> 180806 
 2514.00            MOVE ZNGN-ZPOLICY           TO WSAA-ZNGN-ZPOLICY(ZNGN-I)     <ATHC84> 180806 
 2515.00            MOVE ZNGN-ZLFCODE           TO WSAA-ZNGN-ZLFCODE(ZNGN-I)     <ATHC84> 180806 
 2516.00       *                                                                          160407 
 2517.00       * Delete ZNGP record                                                       160407 
 2518.00       *                                                                          160407 
 2519.00            MOVE DELET                  TO ZNGN-FUNCTION                          160916 
 2520.00            PERFORM N300-ZNGNIO                                                   160916 
 2521.00       *                                                                          160407 
 2522.00       * Setup next read of ZNGN                                                  160407 
 2523.00       *                                                                          160407 
 2524.00            MOVE NEXTR                  TO ZNGN-FUNCTION                          160916 
 2525.00       *                                                                          160407 
 2526.00            .                                                                     160916 
 2527.00        5590-EXIT.                                                                160407 
 2528.00            EXIT.                                                                 160407 
 2529.00       /                                                                          160407 
 2530.00        5600-PROCESS-LIVES SECTION.                                               160407 
 2531.00       ****************************                                               160407 
 2532.00        5610-START.                                                               160407 
 2533.00       *                                                                          160407 
 2534.00       * Get life client details                                                  160407 
 2535.00       *                                                                          160407 
 2536.00            MOVE WSAA-LIFCNUM(IX)       TO WSAA-WORK-CLNTNUM                      160916 
 2537.00            PERFORM 10000-READ-CLNT                                               160916 
 2538.00       *                                                                          160407 
 2539.00       * Check if life member already exists in current ZNGC array                160407 
 2540.00       *                                                                          160407 
 2541.00            SET MEMBER-NOT-FOUND        TO TRUE                                   160916 
 2542.00       *                                                                          160407 
 2543.00            PERFORM VARYING IZ        FROM 1 BY 1                                 160407 
 2544.00              UNTIL IZ                   > WSCC-MAX-LIVES                         160407 
 2545.00                OR WSAA-ZNGC-ZLFCODE(IZ) = SPACES                                 160407 
 2546.00                OR MEMBER-FOUND                                                   160407 
 2547.00               IF  WSAA-LIFCNUM-CCSNOCL(IX)                                       160407 
 2548.00                                         = WSAA-ZNGC-ZLFCODE(IZ)                  160407 
 2549.00                   SET MEMBER-FOUND     TO TRUE                                   160407 
 2550.00               END-IF                                                             160407 
 2551.00            END-PERFORM.                                                          160916 
 2552.00       *                                                                          160407 
 2553.00        5650-PROCESS-LIFE-COVERAGES.                                              160407 
 2554.00       *                                                                          160407 
 2555.00       * Read all the coverages for the life and process accordingly              160407 
 2556.00       *                                                                          160407 
 2557.00            INITIALIZE                     COVR-PARAMS                            160407 
 2558.00                                           COVRREC-KEY-DATA                       160407 
 2559.00                                           WSKY-COVR-KEY                          160916 
 2560.00            MOVE WSAA-WORK-CHDRCOY      TO COVR-CHDRCOY                           160916 
 2561.00            MOVE WSAA-WORK-CHDRNUM      TO COVR-CHDRNUM                           160916 
 2562.00            MOVE WSAA-LIFCNUM-LIFE(IX)  TO COVR-LIFE                              160916 
 2563.00            MOVE COVR-DATA-KEY          TO WSKY-COVR-KEY                          160916 
 2564.00            MOVE COVRREC                TO COVR-FORMAT                            160916 
 2565.00            MOVE BEGN                   TO COVR-FUNCTION                          160916 
 2566.00            MOVE O-K                    TO COVR-STATUZ                            160916 
 2567.00       *                                                                          160407 
 2568.00            PERFORM 5700-PROCESS-COVR                                             160407 
 2569.00              UNTIL COVR-STATUZ          = ENDP                                   160916 
 2570.00       *                                                                          160407 
 2571.00            .                                                                     160916 
 2572.00        5690-EXIT.                                                                160407 
 2573.00            EXIT.                                                                 160407 
 2574.00       /                                                                          160407 
 2575.00        5700-PROCESS-COVR SECTION.                                                160407 
 2576.00       ***************************                                                160407 
 2577.00        5710-START.                                                               160407 
 2578.00       *                                                                          160407 
 2579.00            CALL 'COVRIO'            USING COVR-PARAMS                            160916 
 2580.00       *                                                                          160407 
 2581.00            IF  COVR-STATUZ          NOT = O-K                                    160407 
 2582.00            AND COVR-STATUZ          NOT = ENDP                                   160407 
 2583.00                MOVE COVR-PARAMS        TO SYSR-PARAMS                            160407 
 2584.00                MOVE COVR-STATUZ        TO SYSR-STATUZ                            160407 
 2585.00                PERFORM 600-FATAL-ERROR                                           160407 
 2586.00            END-IF                                                                160916 
 2587.00       *                                                                          160407 
 2588.00       * If eof or change of key then exit loop processing                        160407 
 2589.00       *                                                                          160407 
 2590.00            IF  COVR-STATUZ              = ENDP                                   160407 
 2591.00            OR  COVR-CHDRCOY         NOT = WSKY-COVR-CHDRCOY                      160407 
 2592.00            OR  COVR-CHDRNUM         NOT = WSKY-COVR-CHDRNUM                      160407 
 2593.00            OR  COVR-LIFE            NOT = WSKY-COVR-LIFE                         160407 
 2594.00                MOVE ENDP               TO COVR-STATUZ                            160407 
 2595.00                GO TO 5790-EXIT                                                   160407 
 2596.00            END-IF                                                                160916 
 2597.00       *                                                                          160407 
 2598.00       * Setup next read of COVR logical                                          160407 
 2599.00       *                                                                          160407 
 2600.00            MOVE NEXTR                  TO COVR-FUNCTION                          160916 
 2601.00       *                                                                          160407 
 2602.00       * We are only interested in vf1 records                                    160407 
 2603.00       *                                                                          160407 
 2604.00            IF  COVR-VALIDFLAG       NOT = WSCC-1                                 160407 
 2605.00                GO TO 5790-EXIT                                                   160407 
 2606.00            END-IF                                                                160916 
 2607.00                                                                         <ATHC84> 180801 
 2608.00       * If the coverage has been expired don't send it to MedNet.       <ATHC84> 180801 
 2609.00            MOVE COVR-STATCODE          TO LSTS-STATUZ                   <ATHC84> 180801 
 2610.00            IF  LSTS-COVR-EXPIRED                                        <ATHC84> 180801 
 2611.00                GO TO 5790-EXIT                                          <ATHC84> 180801 
 2612.00            END-IF                                                       <ATHC84> 180801 
 2613.00       *                                                                          160407 
 2614.00       * Check joint life (if spaces then default 00)                             160407 
 2615.00       *                                                                          160407 
 2616.00            IF  COVR-JLIFE               = SPACES                                 160407 
 2617.00                MOVE WSCC-00            TO COVR-JLIFE                             160407 
 2618.00            END-IF                                                                160916 
 2619.00       *                                                                          160407 
 2620.00            IF  COVR-JLIFE           NOT = WSAA-LIFCNUM-JLIFE(IX)                 160407 
 2621.00                GO TO 5790-EXIT                                                   160407 
 2622.00            END-IF                                                                160916 
 2623.00       *                                                                          160407 
 2624.00       * Check if MEDNET coverage by reading T5Z48. If item does not              160407 
 2625.00       * exist then get next coverage record for the life.                        160407 
 2626.00       *                                                                          160407 
 2627.00            MOVE COVR-CRTABLE           TO WSAA-WORK-CRTABLE                      160916 
 2628.00            MOVE COVR-RERATE-FROM-DATE    TO WSAA-RERATE-FROM-DATE       <ATHC60> 180608 
 2629.00            PERFORM 13000-READ-T5Z48                                              160916 
 2630.00       *                                                                          160407 
 2631.00       **** IF  ITEM-STATUZ          NOT = O-K                           <ATHC60> 180606 
 2632.00            IF  ITDM-STATUZ          NOT = O-K                           <ATHC60> 180606 
 2633.00                GO TO 5790-EXIT                                                   160407 
 2634.00            END-IF                                                                160916 
 2635.00       *                                                                          160407 
 2636.00       * For renewal we store the coverage current from date                      160407 
 2637.00       *                                                                          160407 
 2638.00            IF  TRAN-RENEWAL                                                      160407 
 2639.00                MOVE COVR-CURRFROM      TO WSAA-REN-EFF-DATE                      160411 
 2640.00            END-IF                                                                160916 
 2641.00       *                                                                          160407 
 2642.00       * Initialize w/s fields & indexes                                          160407 
 2643.00       *                                                                          160407 
 2644.00            INITIALIZE                     WSAA-WORK-CRCODE                       160407 
 2645.00                                           WSAA-WORK-CAT-SP                       160407 
 2646.00                                           WSAA-CATEGORY-KEY                      160407 
 2647.00                                           IY-TABLE                               160407 
 2648.00                                           WSAA-IY                                160916 
 2649.00       *                                                                          160407 
 2650.00            MOVE 1                      TO IX-TABLE.                              160916 
 2651.00       *                                                                          160407 
 2652.00        5750-CREATE-MEMBER-DETAILS.                                               160407 
 2653.00       *                                                                          160407 
 2654.00       * Create new ZMDC/ZNGC member cover details for the life insured           160407 
 2655.00       * as well as any notes in ZMDN/ZNGN.                                       160407 
 2656.00       *                                                                          160407 
 2657.00            PERFORM 5800-CREATE-MEMBER-DETAILS                                    160916 
 2658.00       *                                                                          160407 
 2659.00            .                                                                     160916 
 2660.00        5790-EXIT.                                                                160407 
 2661.00            EXIT.                                                                 160407 
 2662.00       /                                                                          160407 
 2663.00        5800-CREATE-MEMBER-DETAILS SECTION.                                       160407 
 2664.00       ************************************                                       160407 
 2665.00        5810-START.                                                               160407 
 2666.00       *                                                                          160407 
 2667.00       * Initialize ZMDC/ZNGC & ZMDN/ZNGN records                                 160407 
 2668.00       * (Member Cover & Note details)                                            160407 
 2669.00       *                                                                          160407 
 2670.00            INITIALIZE                     ZMDC-PARAMS                            160407 
 2671.00                                           ZNGC-PARAMS                            160407 
 2672.00                                           ZMDN-PARAMS                            160407 
 2673.00                                           ZNGN-PARAMS                            160916 
 2674.00       *                                                                          160407 
 2675.00       * Setup Member Policy no                                                   160407 
 2676.00       *                                                                          160407 
 2677.00            MOVE WSAA-WORK-CHDRNUM      TO ZMDC-ZPOLICY                           160407 
 2678.00                                           ZNGC-ZPOLICY                           160916 
 2679.00       *                                                                          160407 
 2680.00       * Setup Member CCS no (with leading spaces)                                160407 
 2681.00       *                                                                          160407 
 2682.00            MOVE WSAA-LIFCNUM-CCSNOCL(IX)                                         160407 
 2683.00                                        TO ZMDC-ZLFCODE                           160407 
 2684.00                                           ZNGC-ZLFCODE                           160916 
 2685.00       *                                                                          160407 
 2686.00       * Setup Member First Name                                                  160407 
 2687.00       *                                                                          160407 
 2688.00            MOVE CLNT-GIVNAME           TO ZMDC-ZFIRSTNM                          160407 
 2689.00                                           ZNGC-ZFIRSTNM                          160916 
 2690.00       *                                                                          160407 
 2691.00       * Setup Member Surname                                                     160407 
 2692.00       *                                                                          160407 
 2693.00            MOVE CLNT-SURNAME           TO ZMDC-ZLASTNM                           160407 
 2694.00                                           ZNGC-ZLASTNM                           160916 
 2695.00       *                                                                          160407 
 2696.00       * Setup Member Identity code                                               160407 
 2697.00       *                                                                          160407 
 2698.00            MOVE CLNT-JIDCODE           TO ZMDC-JENTID                            160407 
 2699.00                                           ZNGC-JENTID                            160916 
 2700.00       *                                                                          160407 
 2701.00       * Setup Member Date of birth                                               160407 
 2702.00       *                                                                          160407 
 2703.00            MOVE CLNT-CLTDOB            TO WSAA-DATCON1-DATE                      160916 
 2704.00            MOVE SPACES                 TO WSAA-DESC-DATE                         160916 
 2705.00            MOVE '5800-CLTDOB'          TO WSAA-DESC-DATE                         160916 
 2706.00            PERFORM 16000-CONVERT-DATE                                            160916 
 2707.00            MOVE DTC1-EXT-DATE          TO ZMDC-ZBRTHDTE                          160407 
 2708.00                                           ZNGC-ZBRTHDTE                          160916 
 2709.00       *                                                                          160407 
 2710.00       * Setup Member Tax ID                                                      160407 
 2711.00       *                                                                          160407 
 2712.00            IF  CLNT-JTAXNUM             = SPACES                                 160407 
 2713.00                MOVE SPACES             TO ZMDC-ZMDID                             160407 
 2714.00                                           ZNGC-ZMDID                             160407 
 2715.00            ELSE                                                                  160407 
 2716.00                MOVE CLNT-JTAXNUM       TO ZMDC-ZMDID                             160407 
 2717.00                                           ZNGC-ZMDID                             160407 
 2718.00            END-IF                                                                160916 
 2719.00       *                                                                          160407 
 2720.00       * Setup Member Paid To Date & Effdate from Risk Comm Date.                 160407 
 2721.00       *                                                                          160407 
 2722.00            MOVE CHDRINP-OCCDATE        TO WSAA-DATCON1-DATE                      160916 
 2723.00            MOVE SPACES                 TO WSAA-DESC-DATE                         160916 
 2724.00            MOVE '5800-OCCD'            TO WSAA-DESC-DATE                         160916 
 2725.00            PERFORM 16000-CONVERT-DATE                                            160916 
 2726.00            MOVE DTC1-EXT-DATE          TO ZMDC-ZPTDATE                           160407 
 2727.00                                           ZNGC-ZPTDATE                           160916 
 2728.00            MOVE DTC1-EXT-DATE          TO ZMDC-EFFCDTE                           160407 
 2729.00                                           ZNGC-EFFCDTE                           160916 
 2730.00       *                                                                          160407 
 2731.00       * Setup Member Sex Type                                                    160407 
 2732.00       *                                                                          160407 
 2733.00            MOVE CLNT-CLTSEX            TO ZMDC-ZMDSEX                            160407 
 2734.00                                           ZNGC-ZMDSEX                            160916 
 2735.00       *                                                                          160407 
 2736.00       * Setup Member MEDNET User No (Either 1,2,3,4)                             160407 
 2737.00       *                                                                          160407 
 2738.00            MOVE WSAA-LIFCNUM-USERX(IX) TO ZMDC-USERX                             160407 
 2739.00                                           ZNGC-USERX                             160916 
 2740.00       *                                                                          160407 
 2741.00       * Setup Member Room Classs. Default is U.                                  160407 
 2742.00       * Processing differs according to T5Z48 activation code.                   160407 
 2743.00       *                                                                          160407 
 2744.00            MOVE WSCC-U                 TO ZMDC-ZROOMCL                           160407 
 2745.00                                           ZNGC-ZROOMCL                           160916 
 2746.00       *                                                                          160407 
 2747.00            EVALUATE TRUE                                                         160407 
 2748.00             WHEN T5Z48-ACTVCODE         = WSCC-1                                 160407 
 2749.00                  MOVE T5Z48-ZDESCR(1:4)                                          160407 
 2750.00                                        TO WSAA-WORK-CRCODE                       160407 
 2751.00                  PERFORM 6300-READ-LEXT                                          160407 
 2752.00            END-EVALUATE                                                          160916 
 2753.00       *                                                                          160407 
 2754.00       * Setup Registration no (ie Main Life CCS with leading spaces)             160407 
 2755.00       *                                                                          160407 
 2756.00            MOVE WSAA-MAIN-CCSNOCL      TO ZMDC-JREGNO                            160407 
 2757.00                                           ZNGC-JREGNO                            160916 
 2758.00       *                                                                          160407 
 2759.00       * Setup X-Ref ind (Default is N). Check if life client                     160407 
 2760.00       * already exists in ZNGCCLN for a different policy.                        160407 
 2761.00       * If so, set the X-Ref indicator to Y.                                     160407 
 2762.00       *                                                                          160407 
 2763.00            MOVE WSCC-N                 TO ZMDC-JXREFNUM                          160407 
 2764.00                                           ZNGC-JXREFNUM                          160916 
 2765.00       *                                                                          160407 
 2766.00            INITIALIZE                     ZNGCCLN-PARAMS                         160916 
 2767.00            MOVE ZMDC-ZLFCODE           TO ZNGCCLN-ZLFCODE                        160916 
 2768.00            MOVE BEGN                   TO ZNGCCLN-FUNCTION                       160916 
 2769.00            MOVE O-K                    TO ZNGCCLN-STATUZ                         160916 
 2770.00       *                                                                          160407 
 2771.00            PERFORM 5900-PROCESS-ZNGCCLN                                          160407 
 2772.00              UNTIL ZNGCCLN-STATUZ       = ENDP                                   160916 
 2773.00       *                                                                          160407 
 2774.00       * Setup package code. Default is 9999999999.                               160407 
 2775.00       * Also check T6Z33 and particular clauses.                                 160407 
 2776.00       *                                                                          160407 
 2777.00            MOVE WSCC-10-NINES          TO ZMDC-ZPACKCOD                          160407 
 2778.00                                           ZNGC-ZPACKCOD                          160916 
 2779.00       *                                                                          160407 
 2780.00            PERFORM 6500-PACKAGE-CODE.                                            160407 
 2781.00       *                                                                          160407 
 2782.00       * Setup marital status (Default spaces)                                    160407 
 2783.00       *                                                                          160407 
 2784.00            MOVE SPACES                 TO ZMDC-ZMARSTAT                          160407 
 2785.00                                           ZNGC-ZMARSTAT                          160916 
 2786.00       *                                                                          160407 
 2787.00       * Setup client address (Life)                                              160407 
 2788.00       *                                                                          160407 
 2789.00            STRING CLNT-CLTADDR01       DELIMITED BY SIZE                         160407 
 2790.00                   CLNT-CLTADDR02(1:10) DELIMITED BY SIZE                         160407 
 2791.00                   CLNT-CLTADDR03(1:20) DELIMITED BY SIZE                         160407 
 2792.00                   CLNT-CLTADDR04(1:20) DELIMITED BY SIZE                         160407 
 2793.00                                      INTO ZMDC-ZMDADR                            160916 
 2794.00            MOVE ZMDC-ZMDADR            TO ZNGC-ZMDADR                            160916 
 2795.00       *                                                                          160407 
 2796.00       * Setup client address postcode (Life)                                     160407 
 2797.00       *                                                                          160407 
 2798.00            MOVE CLNT-CLTPCODE          TO ZMDC-ZMDZIP                            160407 
 2799.00                                           ZNGC-ZMDZIP                            160916 
 2800.00       *                                                                          160407 
 2801.00       * Setup client fax no (Life)                                               160407 
 2802.00       *                                                                          160407 
 2803.00            MOVE SPACES                 TO ZMDC-ZMDFAX                            160407 
 2804.00                                           ZNGC-ZMDFAX                            160916 
 2805.00       *                                                                          160407 
 2806.00       * Setup client phone 1 details                                             160407 
 2807.00       *                                                                          160407 
 2808.00            MOVE CLNT-CLTPHONE01        TO ZMDC-ZMDPHA                            160407 
 2809.00                                           ZNGC-ZMDPHA                            160916 
 2810.00       *                                                                          160407 
 2811.00       * Setup client phone 2 details                                             160407 
 2812.00       *                                                                          160407 
 2813.00            MOVE CLNT-CLTPHONE02        TO ZMDC-ZMDPHB                            160407 
 2814.00                                           ZNGC-ZMDPHB                            160916 
 2815.00       *                                                                          160407 
 2816.00       * Setup tran type                                                          160407 
 2817.00       *                                                                          160407 
 2818.00            PERFORM 6700-DETERMINE-ZMDC-ZTRNTYP                                   160916 
 2819.00       *                                                                          160407 
 2820.00            MOVE WSAA-WORK-ZTRNTYP      TO ZMDC-ZTRNTYP                           160407 
 2821.00                                           ZNGC-ZTRNTYP                           160916 
 2822.00       *                                                                          160407 
 2823.00       * Setup sequence no                                                        160407 
 2824.00       *                                                                          160407 
 2825.00            ADD WSCC-1                  TO WSAA-SEQNUM                            160916 
 2826.00            PERFORM 15000-DELETE-SEQ-ZEROES                                       160916 
 2827.00            MOVE WSAA-SEQ-NUMBERS       TO ZMDC-ZTRNNUM                           160407 
 2828.00                                           ZNGC-ZTRNNUM                           160916 
 2829.00       *                                                                          160407 
 2830.00       * Setup Modification Date                                                  160407 
 2831.00       * - Default to spaces                                                      160407 
 2832.00       * - If not initial policy set to PTRN transaction date                     160407 
 2833.00       *                                                                          160407 
 2834.00            MOVE SPACES                 TO ZMDC-ZMODDTE                           160407 
 2835.00                                           ZNGC-ZMODDTE                           160916 
 2836.00       *                                                                          160407 
 2837.00       * If tran type not 01 (ie Not Initial Policy)                              160407 
 2838.00       *                                                                          160407 
 2839.00            IF ZMDC-ZTRNTYP          NOT = WSCC-01                                160407 
 2840.00               MOVE BSSC-EFFECTIVE-DATE TO WSAA-DATCON1-DATE                      160412 
 2841.00               MOVE SPACES              TO WSAA-DESC-DATE                         160407 
 2842.00               MOVE '6200-BSSC'         TO WSAA-DESC-DATE                         160407 
 2843.00               PERFORM 16000-CONVERT-DATE                                         160407 
 2844.00               MOVE DTC1-EXT-DATE       TO ZMDC-ZMODDTE                           160407 
 2845.00                                           ZNGC-ZMODDTE                           160407 
 2846.00            END-IF                                                                160916 
 2847.00       *                                                                          160407 
 2848.00       * If modifying member then initialize certain fields                       160407 
 2849.00       *                                                                          160407 
 2850.00            IF  ZMDC-ZTRNTYP             = WSCC-43                                160407 
 2851.00                MOVE SPACES             TO ZMDC-EFFCDTE                           160407 
 2852.00                                           ZNGC-EFFCDTE                           160407 
 2853.00                                           ZMDC-ZPTDATE                           160407 
 2854.00                                           ZNGC-ZPTDATE                           160407 
 2855.00            END-IF                                                                160916 
 2856.00       *                                                                 <ATHD10> 190329 
 2857.00       * If adding a member                                              <ATHD10> 190329 
 2858.00       * Setup Member Paid To Date & Effdate from Risk Comm Date.        <ATHD10> 190329 
 2859.00       *                                                                 <ATHD10> 190329 
 2860.00            IF  ZMDC-ZTRNTYP             = WSCC-42                       <ATHD10> 190329 
 2861.00               MOVE COVR-CRRCD          TO WSAA-DATCON1-DATE             <ATHD10> 190329 
 2862.00               MOVE SPACES              TO WSAA-DESC-DATE                <ATHD10> 190329 
 2863.00               MOVE '5800-CRRC'         TO WSAA-DESC-DATE                <ATHD10> 190329 
 2864.00               PERFORM 16000-CONVERT-DATE                                <ATHD10> 190329 
 2865.00               MOVE DTC1-EXT-DATE       TO ZMDC-ZPTDATE                  <ATHD10> 190401 
 2866.00                                           ZNGC-ZPTDATE                  <ATHD10> 190401 
 2867.00               MOVE DTC1-EXT-DATE       TO ZMDC-EFFCDTE                  <ATHD10> 190329 
 2868.00                                           ZNGC-EFFCDTE                  <ATHD10> 190329 
 2869.00            END-IF                                                       <ATHD10> 190329 
 2870.00       *                                                                          160407 
 2871.00       * If special processing (ie T514 Lapse or T557 Comp Add)                   160407 
 2872.00       * then modification date will be the PTRN effdate                          160407 
 2873.00       *                                                                          160407 
 2874.00            IF  TRAN-SPECIAL                                                      160407 
 2875.00                MOVE WSAA-WORK-EFFDATE  TO WSAA-DATCON1-DATE                      160412 
 2876.00                MOVE SPACES             TO WSAA-DESC-DATE                         160407 
 2877.00                MOVE '6200-ZPTR-EFF'    TO WSAA-DESC-DATE                         160407 
 2878.00                PERFORM 16000-CONVERT-DATE                                        160407 
 2879.00                MOVE DTC1-EXT-DATE      TO ZMDC-ZMODDTE                           160407 
 2880.00                                           ZNGC-ZMODDTE                           160407 
 2881.00            END-IF                                                                160916 
 2882.00       *                                                                          160407 
 2883.00       * When we have Renewal Re Rate Transaction the modification                160407 
 2884.00       * date must be the effective date of the coverage.                         160407 
 2885.00       *                                                                          160407 
 2886.00            IF  TRAN-RENEWAL                                                      160407 
 2887.00                MOVE WSAA-REN-EFF-DATE  TO WSAA-DATCON1-DATE                      160412 
 2888.00                MOVE SPACES             TO WSAA-DESC-DATE                         160407 
 2889.00                MOVE '5800-REN-EFF'     TO WSAA-DESC-DATE                         160407 
 2890.00                PERFORM 16000-CONVERT-DATE                                        160407 
 2891.00                MOVE DTC1-EXT-DATE      TO ZMDC-ZMODDTE                           160407 
 2892.00                                           ZNGC-ZMODDTE                           160407 
 2893.00            END-IF                                                                160916 
 2894.00       *                                                                          160407 
 2895.00       * Setup Cancellation Date                                                  160407 
 2896.00       * - Default to spaces                                                      160407 
 2897.00       * - If policy/member not inforce set to PTRN transaction date              160407 
 2898.00       * - Set package code to 0000000000                                         160407 
 2899.00       *                                                                          160407 
 2900.00            MOVE SPACES                 TO ZMDC-ZCANDTE                           160407 
 2901.00                                           ZNGC-ZCANDTE                           160916 
 2902.00       *                                                                          160407 
 2903.00            IF  ZMDC-ZTRNTYP             = WSCC-40                                160407 
 2904.00                MOVE WSAA-TRANS-DATE-NEW                                          160407 
 2905.00                                        TO WSAA-DATCON1-DATE                      160412 
 2906.00                MOVE SPACES             TO WSAA-DESC-DATE                         160407 
 2907.00                MOVE '6200-ZPTREFC'     TO WSAA-DESC-DATE                         160407 
 2908.00                PERFORM 16000-CONVERT-DATE                                        160407 
 2909.00                MOVE DTC1-EXT-DATE      TO ZMDC-ZCANDTE                           160407 
 2910.00                                           ZNGC-ZCANDTE                           160407 
 2911.00                MOVE WSCC-10-ZEROES     TO ZMDC-ZPACKCOD                          160407 
 2912.00                                           ZNGC-ZPACKCOD                          160407 
 2913.00            END-IF                                                                160916 
 2914.00       *                                                                          160407 
 2915.00       * Setup Cancellation Type (Default Spaces)                                 160407 
 2916.00       *                                                                          160407 
 2917.00            MOVE SPACES                 TO ZMDC-ZCANTYP                           160407 
 2918.00                                           ZNGC-ZCANTYP                           160916 
 2919.00       *                                                                          160407 
 2920.00       * Setup Father/Spouse Name (Default Spaces)                                160407 
 2921.00       *                                                                          160407 
 2922.00            MOVE SPACES                 TO ZMDC-JFTNAME                           160407 
 2923.00                                           ZNGC-JFTNAME                           160916 
 2924.00       *                                                                          160407 
 2925.00       * Setup Internation First Name (Default Spaces)                            160407 
 2926.00       *                                                                          160407 
 2927.00            MOVE SPACES                 TO ZMDC-ZINTFNME                          160407 
 2928.00                                           ZNGC-ZINTFNME                          160916 
 2929.00       *                                                                          160407 
 2930.00       * Setup Internation Middle Name (Default Spaces)                           160407 
 2931.00       *                                                                          160407 
 2932.00            MOVE SPACES                 TO ZMDC-ZINTMNME                          160407 
 2933.00                                           ZNGC-ZINTMNME                          160916 
 2934.00       *                                                                          160407 
 2935.00       * Setup Internation Last Name (Default Spaces)                             160407 
 2936.00       *                                                                          160407 
 2937.00            MOVE SPACES                 TO ZMDC-ZINTLNME                          160407 
 2938.00                                           ZNGC-ZINTLNME                          160916 
 2939.00       *                                                                          160407 
 2940.00       * Setup Member Number (Default Spaces)                                     160407 
 2941.00       *                                                                          160407 
 2942.00            MOVE SPACES                 TO ZMDC-ZMEMBNUM                          160407 
 2943.00                                           ZNGC-ZMEMBNUM                          160916 
 2944.00       *                                                                          160407 
 2945.00       * Setup Member Nationality (Default GR)                                    160407 
 2946.00       *                                                                          160407 
 2947.00            MOVE WSCC-GR                TO ZMDC-ZMDNATIO                          160407 
 2948.00                                           ZNGC-ZMDNATIO                          160916 
 2949.00       *                                                                          160407 
 2950.00       * Setup Member Default Value (Default Spaces)                              160407 
 2951.00       *                                                                          160407 
 2952.00            MOVE SPACES                 TO ZMDC-JDFTVAL                           160407 
 2953.00                                           ZNGC-JDFTVAL                           160916 
 2954.00       *                                                                          160407 
 2955.00       * Setup Member country of residence (Default GR)                           160407 
 2956.00       *                                                                          160407 
 2957.00            MOVE WSCC-GR                TO ZMDC-ZMDRES                            160407 
 2958.00                                           ZNGC-ZMDRES                            160916 
 2959.00       *                                                                          160407 
 2960.00       * Setup containder type (Life). Will be occupation code.                   160407 
 2961.00       *                                                                          160407 
 2962.00            MOVE CLNT-OCCPCODE          TO ZMDC-CONTTYPE(1:4)                     160407 
 2963.00                                           ZNGC-CONTTYPE(1:4)                     160916 
 2964.00            MOVE SPACES                 TO ZMDC-CONTTYPE(5:6)                     160407 
 2965.00                                           ZNGC-CONTTYPE(5:6)                     160916 
 2966.00       *                                                                          160407 
 2967.00       * Setup Member Bank Account no (Default Spaces)                            160407 
 2968.00       *                                                                          160407 
 2969.00            MOVE SPACES                 TO ZMDC-ZBNKNUM                           160407 
 2970.00                                           ZNGC-ZBNKNUM                           160916 
 2971.00       *                                                                          160407 
 2972.00       * Set Member Bank Account Holder (Default Spaces)                          160407 
 2973.00       *                                                                          160407 
 2974.00            MOVE SPACES                 TO ZMDC-ZMDACCH                           160407 
 2975.00                                           ZNGC-ZMDACCH                           160916 
 2976.00       *                                                                          160407 
 2977.00       * Setup Member Country (Default Spaces)                                    160407 
 2978.00       *                                                                          160407 
 2979.00            MOVE SPACES                 TO ZMDC-ZCONTR                            160407 
 2980.00                                           ZNGC-ZCONTR                            160916 
 2981.00       *                                                                          160407 
 2982.00       * Setup Member City (Default Spaces)                                       160407 
 2983.00       *                                                                          160407 
 2984.00            MOVE SPACES                 TO ZMDC-ZCITY                             160407 
 2985.00                                           ZNGC-ZCITY                             160916 
 2986.00       *                                                                          160407 
 2987.00       * Setup Checkbox Subfile Selection (Default Spaces)                        160407 
 2988.00       *                                                                          160407 
 2989.00            MOVE SPACES                 TO ZMDC-JLBL                              160407 
 2990.00                                           ZNGC-JLBL                              160916 
 2991.00       *                                                                          160407 
 2992.00       * Setup Codice Anno (Default Spaces)                                       160407 
 2993.00       *                                                                          160407 
 2994.00            MOVE SPACES                 TO ZMDC-ZCDEANNO                          160407 
 2995.00                                           ZNGC-ZCDEANNO                          160916 
 2996.00       *                                                                          160407 
 2997.00       * Setup Member Entity Type Desc (Default Spaces)                           160407 
 2998.00       *                                                                          160407 
 2999.00            MOVE SPACES                 TO ZMDC-ENTYDESC                          160407 
 3000.00                                           ZNGC-ENTYDESC                          160916 
 3001.00       *                                                                          160407 
 3002.00       * Setup Member IBAN (Default Spaces)                                       160407 
 3003.00       *                                                                          160407 
 3004.00            MOVE SPACES                 TO ZMDC-ZMDIBAN                           160407 
 3005.00                                           ZNGC-ZMDIBAN                           160916 
 3006.00       *                                                                          160407 
 3007.00       * Setup Member Long External Ref (Default Spaces)                          160407 
 3008.00       *                                                                          160407 
 3009.00            MOVE SPACES                 TO ZMDC-ZLEXTREF                          160407 
 3010.00                                           ZNGC-ZLEXTREF                          160916 
 3011.00       *                                                                          160407 
 3012.00       * Setup Member Long External main life Ref (Default Spaces)                160407 
 3013.00       *                                                                          160407 
 3014.00            MOVE SPACES                 TO ZMDC-ZLEXTPR                           160407 
 3015.00                                           ZNGC-ZLEXTPR                           160916 
 3016.00       *                                                                          160407 
 3017.00       * Setup Member Confirmed Dat of birth (Default Spaces)                     160407 
 3018.00       *                                                                          160407 
 3019.00            MOVE SPACES                 TO ZMDC-ZCONFDAT                          160407 
 3020.00                                           ZNGC-ZCONFDAT                          160916 
 3021.00       *                                                                          160407 
 3022.00       * Setup Member Bank Details (Default Spaces)                               160407 
 3023.00       *                                                                          160407 
 3024.00            MOVE SPACES                 TO ZMDC-ZBANKC                            160407 
 3025.00                                           ZNGC-ZBANKC                            160916 
 3026.00       *                                                                          160407 
 3027.00       * Write the valid record in ZMDC file                                      160407 
 3028.00       *                                                                          160407 
 3029.00            MOVE WRITR                  TO ZMDC-FUNCTION                          160916 
 3030.00            PERFORM M200-ZMDCIO                                                   160916 
 3031.00       *                                                                          160407 
 3032.00       * Setup Control Total                                                      160407 
 3033.00       *                                                                          160407 
 3034.00       * CT02 - Total ZMDC records written                                        160408 
 3035.00       *                                                                          160408 
 3036.00            MOVE CT02                   TO CONT-TOTNO                             160916 
 3037.00            MOVE 1                      TO CONT-TOTVAL                            160916 
 3038.00            PERFORM 001-CALL-CONTOT                                               160916 
 3039.00       *                                                                          160407 
 3040.00       * CT07 - Total ZMDC initial records written                                160408 
 3041.00       *                                                                          160408 
 3042.00            IF  ZMDC-ZTRNTYP             = WSCC-01                                160407 
 3043.00                MOVE CT07               TO CONT-TOTNO                             160407 
 3044.00                MOVE 1                  TO CONT-TOTVAL                            160407 
 3045.00                PERFORM 001-CALL-CONTOT                                           160407 
 3046.00            END-IF                                                                160916 
 3047.00       *                                                                          160407 
 3048.00       * CT08 - Total ZMDC modify records written                                 160408 
 3049.00       *                                                                          160408 
 3050.00            IF  ZMDC-ZTRNTYP             = WSCC-41                                160407 
 3051.00            OR  ZMDC-ZTRNTYP             = WSCC-43                                160408 
 3052.00                MOVE CT08               TO CONT-TOTNO                             160407 
 3053.00                MOVE 1                  TO CONT-TOTVAL                            160407 
 3054.00                PERFORM 001-CALL-CONTOT                                           160407 
 3055.00            END-IF                                                                160916 
 3056.00       *                                                                          160407 
 3057.00       * CT09 - Total ZMDC cancel records written                                 160408 
 3058.00       *                                                                          160408 
 3059.00            IF  ZMDC-ZTRNTYP             = WSCC-40                                160408 
 3060.00                MOVE CT09               TO CONT-TOTNO                             160407 
 3061.00                MOVE 1                  TO CONT-TOTVAL                            160407 
 3062.00                PERFORM 001-CALL-CONTOT                                           160407 
 3063.00            END-IF                                                                160916 
 3064.00       *                                                                          160408 
 3065.00       * CT10 - Total ZMDC member addition records written                        160408 
 3066.00       *                                                                          160408 
 3067.00            IF  ZMDC-ZTRNTYP             = WSCC-42                                160408 
 3068.00                MOVE CT10               TO CONT-TOTNO                             160408 
 3069.00                MOVE 1                  TO CONT-TOTVAL                            160408 
 3070.00                PERFORM 001-CALL-CONTOT                                           160408 
 3071.00            END-IF                                                                160916 
 3072.00       *                                                                          160407 
 3073.00       * Write the valid record in ZNGC file                                      160407 
 3074.00       *                                                                          160407 
 3075.00            MOVE WRITR                  TO ZNGC-FUNCTION                          160916 
 3076.00            PERFORM N200-ZNGCIO.                                                  160916 
 3077.00       *                                                                          160407 
 3078.00        5850-CREATE-NOTES.                                                        160407 
 3079.00       *                                                                          160407 
 3080.00       * Setup Member Policy no                                                   160407 
 3081.00       *                                                                          160407 
 3082.00            MOVE ZMDC-ZPOLICY           TO ZMDN-ZPOLICY                           160407 
 3083.00                                           ZNGN-ZPOLICY                           160916 
 3084.00       *                                                                          160407 
 3085.00       * Setup Member CCS no                                                      160407 
 3086.00       *                                                                          160407 
 3087.00            MOVE ZMDC-ZLFCODE           TO ZMDN-ZLFCODE                           160407 
 3088.00                                           ZNGN-ZLFCODE                           160916 
 3089.00       *                                                                          160407 
 3090.00       * Setup sequence no                                                        160407 
 3091.00       *                                                                          160407 
 3092.00            MOVE ZMDC-ZTRNNUM           TO ZMDN-ZTRNNUM                           160407 
 3093.00                                           ZNGN-ZTRNNUM                           160916 
 3094.00       *                                                                          160407 
 3095.00       * Setup Member Note Type                                                   160407 
 3096.00       * ======================                                                   160407 
 3097.00       * 1 = General                                                              160407 
 3098.00       * 2 = Claims                                                               160407 
 3099.00       * 3 = Confidential                                                         160407 
 3100.00       * 4 = Coverage                                                             160407 
 3101.00       * 5 = Underwriting                                                         160407 
 3102.00       *                                                                          160407 
 3103.00            MOVE WSCC-5                 TO ZMDN-ZMDTYPID                          160407 
 3104.00                                           ZNGN-ZMDTYPID                          160916 
 3105.00       *                                                                          160407 
 3106.00       * Clause text (if any)                                                     160407 
 3107.00       *                                                                          160407 
 3108.00            PERFORM 7500-READ-CLAUSES                                             160916 
 3109.00       *                                                                          160407 
 3110.00       * Setup the second part of the Member Note area with member                160407 
 3111.00       * secondary occupation code (if any).                                      160407 
 3112.00       *                                                                          160407 
 3113.00       **** MOVE CLNT-JSECOCC           TO ZMDN-WORK-AREA-DATA           <ATHC84> 180801 
 3114.00       ****                                (1997:4)                      <ATHC84> 180801 
 3115.00       ****                                ZNGN-WORK-AREA-DATA           <ATHC84> 180801 
 3116.00       ****                                (1997:4)                      <ATHC84> 180801 
 3117.00       *                                                                          160407 
 3118.00       * Setup Member Long External Ref (Default Spaces)                          160407 
 3119.00       *                                                                          160407 
 3120.00            MOVE SPACES                 TO ZMDN-ZLEXTREF                          160407 
 3121.00                                           ZNGN-ZLEXTREF                          160916 
 3122.00       *                                                                          160407 
 3123.00       * If CFI status and cancelation date is not spaces then                    160407 
 3124.00       * move CFI standard text to Notes file                                     160407 
 3125.00       *                                                                          160407 
 3126.00            IF  CONTRACT-CFI                                             <ATHC84> 180801 
 3127.00            AND ZMDC-ZCANDTE         NOT = SPACES                        <ATHC84> 180801 
 3128.00                MOVE WSCC-CFI-TEXT      TO ZMDN-WORK-AREA-DATA           <ATHC84> 180801 
 3129.00                                           (1938:58)                              160407 
 3130.00                MOVE WSCC-CFI-TEXT      TO ZNGN-WORK-AREA-DATA                    160407 
 3131.00                                           (1938:58)                              160407 
 3132.00            END-IF                                                                160916 
 3133.00       *                                                                          160407 
 3134.00       * If work area is spaces and the history file ZNGN had recs,      <ATHC84> 180801 
 3135.00       * we create a ZMDN rec to say that the terms are removed.         <ATHC84> 180801 
 3136.00       * If work area is spaces and no recs found in ZNGN, then we don't <ATHC84> 180801 
 3137.00       * create a ZMDN rec and get the next coverage for the life        <ATHC84> 180801 
 3138.00       *                                                                          160407 
 3139.00            IF  ZMDN-WORK-AREA-DATA      = SPACES                                 160407 
 3140.00                                                                         <ATHC84> 180806 
 3141.00                SET INDX-1              TO WSCC-1                        <ATHC84> 180806 
 3142.00                SEARCH WSAA-ZNGN-RECORD                                  <ATHC84> 180806 
 3143.00                  AT END                                                 <ATHC84> 180806 
 3144.00                    SET NOT-FOUND-ZNGN  TO TRUE                          <ATHC84> 180806 
 3145.00                  WHEN WSAA-ZNGN-ZPOLICY(INDX-1) = ZNGN-ZPOLICY AND      <ATHC84> 180806 
 3146.00                       WSAA-ZNGN-ZLFCODE(INDX-1) = ZNGN-ZLFCODE          <ATHC84> 180806 
 3147.00                    SET FOUND-ZNGN  TO TRUE                              <ATHC84> 180806 
 3148.00                END-SEARCH                                               <ATHC84> 180806 
 3149.00                                                                         <ATHC84> 180806 
 3150.00                IF FOUND-ZNGN                                            <ATHC84> 180801 
 3151.00                   MOVE WSCC-TEXT-REMOVE-TERMS                           <ATHC84> 180801 
 3152.00                                        TO ZMDN-WORK-AREA-DATA           <ATHC84> 180801 
 3153.00                                           ZNGN-WORK-AREA-DATA           <ATHC84> 180801 
 3154.00                ELSE                                                     <ATHC84> 180801 
 3155.00                   GO TO 5890-EXIT                                       <ATHC84> 180801 
 3156.00                END-IF                                                   <ATHC84> 180801 
 3157.00            END-IF                                                       <ATHC84> 180801 
 3158.00       *                                                                 <ATHC84> 180801 
 3159.00       * Setup the second part of the Member Note area with member       <ATHC84> 180801 
 3160.00       * secondary occupation code (if any).                             <ATHC84> 180801 
 3161.00       *                                                                 <ATHC84> 180801 
 3162.00            MOVE CLNT-JSECOCC           TO ZMDN-WORK-AREA-DATA           <ATHC84> 180801 
 3163.00                                           (1997:4)                      <ATHC84> 180801 
 3164.00                                           ZNGN-WORK-AREA-DATA           <ATHC84> 180801 
 3165.00                                           (1997:4)                      <ATHC84> 180801 
 3166.00       *                                                                          160407 
 3167.00       * Write the valid record in ZMDN file                                      160407 
 3168.00       *                                                                          160407 
 3169.00            MOVE WRITR                  TO ZMDN-FUNCTION                          160916 
 3170.00            PERFORM M300-ZMDNIO                                                   160916 
 3171.00       *                                                                          160407 
 3172.00       * Setup control total                                                      160407 
 3173.00       *                                                                          160407 
 3174.00       * CT03 - Total ZMDN records written                                        160408 
 3175.00       *                                                                          160408 
 3176.00            MOVE CT03                   TO CONT-TOTNO                             160916 
 3177.00            MOVE 1                      TO CONT-TOTVAL                            160916 
 3178.00            PERFORM 001-CALL-CONTOT                                               160916 
 3179.00       *                                                                          160407 
 3180.00       * Write the valid record in ZNGN file                                      160407 
 3181.00       *                                                                          160407 
 3182.00            MOVE WRITR                  TO ZNGN-FUNCTION                          160916 
 3183.00            PERFORM N300-ZNGNIO                                                   160916 
 3184.00       *                                                                          160407 
 3185.00            .                                                                     160916 
 3186.00        5890-EXIT.                                                                160407 
 3187.00            EXIT.                                                                 160407 
 3188.00       /                                                                          160407 
 3189.00        5900-PROCESS-ZNGCCLN SECTION.                                             160407 
 3190.00       ******************************                                             160407 
 3191.00        5910-START.                                                               160407 
 3192.00       *                                                                          160407 
 3193.00            PERFORM N400-ZNGCCLNIO                                                160916 
 3194.00       *                                                                          160407 
 3195.00       * If eof or change of key then exit loop processing                        160407 
 3196.00       *                                                                          160407 
 3197.00            IF  ZNGCCLN-STATUZ           = ENDP                                   160407 
 3198.00            OR  ZNGCCLN-ZLFCODE      NOT = ZMDC-ZLFCODE                           160407 
 3199.00                MOVE ENDP               TO ZNGCCLN-STATUZ                         160407 
 3200.00                GO TO 5990-EXIT                                                   160407 
 3201.00            END-IF                                                                160916 
 3202.00       *                                                                          160407 
 3203.00       * Setup next read of ZNGCCLN logical                                       160407 
 3204.00       *                                                                          160407 
 3205.00            MOVE NEXTR                  TO ZNGCCLN-FUNCTION                       160916 
 3206.00       *                                                                          160407 
 3207.00       * We are only interested in different contract                             160408 
 3208.00       *                                                                          160407 
 3209.00            IF  ZNGCCLN-ZPOLICY(1:8)     = WSAA-WORK-CHDRNUM                      160411 
 3210.00                GO TO 5990-EXIT                                                   160407 
 3211.00            END-IF                                                                160916 
 3212.00       *                                                                          160407 
 3213.00       * If we reach this point then our life client already exists               160407 
 3214.00       * for a different contract so set X-Ref indicator to Y and                 160407 
 3215.00       * exit loop processing                                                     160407 
 3216.00       *                                                                          160407 
 3217.00            MOVE WSCC-Y                 TO ZNGC-JXREFNUM                          160407 
 3218.00                                           ZMDC-JXREFNUM                          160916 
 3219.00       *                                                                          160407 
 3220.00            MOVE ENDP                   TO ZNGCCLN-STATUZ                         160916 
 3221.00       *                                                                          160407 
 3222.00            .                                                                     160916 
 3223.00        5990-EXIT.                                                                160407 
 3224.00             EXIT.                                                                160407 
 3225.00       /                                                                          160407 
 3226.00        6300-READ-LEXT SECTION.                                                   160407 
 3227.00       ************************                                                   160407 
 3228.00        6310-START.                                                               160407 
 3229.00       *                                                                          160407 
 3230.00       * Read T7Z38 using coverage code.                                          160407 
 3231.00       *                                                                          160407 
 3232.00            INITIALIZE                     ITEM-PARAMS                            160407 
 3233.00                                           T7Z38-T7Z38-REC.                       160407 
 3234.00            MOVE SMTP-ITEM              TO ITEM-ITEMPFX.                          160407 
 3235.00            MOVE BPRD-COMPANY           TO ITEM-ITEMCOY.                          160407 
 3236.00            MOVE T7Z38                  TO ITEM-ITEMTABL.                         160407 
 3237.00            MOVE COVR-CRTABLE           TO ITEM-ITEMITEM.                         160407 
 3238.00       *                                                                          160407 
 3239.00            MOVE READR                  TO ITEM-FUNCTION.                         160407 
 3240.00            PERFORM I100-ITEMIO.                                                  160407 
 3241.00       *                                                                          160407 
 3242.00       * If item not found then exit LEXT processing                              160407 
 3243.00       *                                                                          160407 
 3244.00            IF  ITEM-STATUZ          NOT = O-K                                    160407 
 3245.00                GO TO 6390-EXIT                                                   160407 
 3246.00            END-IF.                                                               160407 
 3247.00       *                                                                          160407 
 3248.00            MOVE ITEM-GENAREA           TO T7Z38-T7Z38-REC.                       160407 
 3249.00       *                                                                          160407 
 3250.00        6320-SPECIAL-TERMS.                                                       160407 
 3251.00       *                                                                          160407 
 3252.00       * Loop thru all the special terms which exist for the coverage             160407 
 3253.00       *                                                                          160407 
 3254.00            INITIALIZE LEXT-PARAMS.                                               160407 
 3255.00            INITIALIZE LEXTREC-KEY-DATA        OF LEXT-PARAMS.                    160407 
 3256.00            INITIALIZE LEXTREC-NON-KEY-DATA    OF LEXT-PARAMS.                    160407 
 3257.00       *                                                                          160407 
 3258.00            MOVE COVR-CHDRCOY           TO LEXT-CHDRCOY.                          160407 
 3259.00            MOVE COVR-CHDRNUM           TO LEXT-CHDRNUM.                          160407 
 3260.00            MOVE COVR-LIFE              TO LEXT-LIFE.                             160407 
 3261.00            MOVE COVR-COVERAGE          TO LEXT-COVERAGE.                         160407 
 3262.00            MOVE LEXTREC                TO LEXT-FORMAT.                           160407 
 3263.00            MOVE BEGN                   TO LEXT-FUNCTION.                         160407 
 3264.00            MOVE O-K                    TO LEXT-STATUZ.                           160407 
 3265.00       *                                                                          160407 
 3266.00            PERFORM 6400-PROCESS-LEXT                                             160407 
 3267.00              UNTIL LEXT-STATUZ          = ENDP.                                  160407 
 3268.00       *                                                                          160407 
 3269.00        6350-PRICING-CATEGORY.                                                    160407 
 3270.00       *                                                                          160407 
 3271.00       * Using the special term comnination setup from all LEXT recs              160407 
 3272.00       * for the coverage, read T7Z37 to get the pricing category.                160407 
 3273.00       *                                                                          160407 
 3274.00            INITIALIZE                     ITEM-PARAMS                            160407 
 3275.00                                           T7Z37-T7Z37-REC.                       160407 
 3276.00            MOVE SMTP-ITEM              TO ITEM-ITEMPFX.                          160407 
 3277.00            MOVE BPRD-COMPANY           TO ITEM-ITEMCOY.                          160407 
 3278.00            MOVE T7Z37                  TO ITEM-ITEMTABL.                         160407 
 3279.00            MOVE COVR-CRTABLE           TO ITEM-ITEMITEM.                         160407 
 3280.00       *                                                                          160407 
 3281.00            MOVE READR                  TO ITEM-FUNCTION.                         160407 
 3282.00            PERFORM I100-ITEMIO.                                                  160407 
 3283.00       *                                                                          160407 
 3284.00            IF  ITEM-STATUZ          NOT = O-K                                    160407 
 3285.00                GO TO 6390-EXIT                                                   160407 
 3286.00            END-IF.                                                               160407 
 3287.00       *                                                                          160407 
 3288.00            MOVE ITEM-GENAREA           TO T7Z37-T7Z37-REC.                       160407 
 3289.00       *                                                                          160407 
 3290.00            PERFORM VARYING IX-SPCAT  FROM 1 BY 1                                 160407 
 3291.00              UNTIL IX-SPCAT             > IX-SPCAT-MAX                           160407 
 3292.00                IF T7Z37-ZSPTRMR(IX-SPCAT)                                        160407 
 3293.00                                         = WSAA-CATEGORY-KEY                      160407 
 3294.00                   MOVE T7Z37-ZPRCCAT(IX-SPCAT)                                   160407 
 3295.00                                        TO WSAA-WORK-CAT-SP                       160407 
 3296.00                END-IF                                                            160407 
 3297.00            END-PERFORM.                                                          160407 
 3298.00       *                                                                          160407 
 3299.00        6390-EXIT.                                                                160407 
 3300.00            EXIT.                                                                 160407 
 3301.00       /                                                                          160407 
 3302.00        6400-PROCESS-LEXT SECTION.                                                160407 
 3303.00       ***************************                                                160407 
 3304.00        6410-START.                                                               160407 
 3305.00       *                                                                          160407 
 3306.00            CALL 'LEXTIO'            USING LEXT-PARAMS.                           160407 
 3307.00       *                                                                          160407 
 3308.00            IF  LEXT-STATUZ          NOT = O-K                                    160407 
 3309.00            AND LEXT-STATUZ          NOT = ENDP                                   160407 
 3310.00                MOVE LEXT-PARAMS        TO SYSR-PARAMS                            160407 
 3311.00                MOVE LEXT-STATUZ        TO SYSR-STATUZ                            160407 
 3312.00                PERFORM 600-FATAL-ERROR                                           160407 
 3313.00            END-IF.                                                               160407 
 3314.00       *                                                                          160407 
 3315.00       * If eof or change of key then exit loop processing                        160407 
 3316.00       *                                                                          160407 
 3317.00            IF  LEXT-STATUZ              = ENDP                                   160407 
 3318.00            OR  LEXT-CHDRCOY         NOT = COVR-CHDRCOY                           160407 
 3319.00            OR  LEXT-CHDRNUM         NOT = COVR-CHDRNUM                           160407 
 3320.00            OR  LEXT-LIFE            NOT = COVR-LIFE                              160407 
 3321.00            OR  LEXT-COVERAGE        NOT = COVR-COVERAGE                          160407 
 3322.00                MOVE ENDP               TO LEXT-STATUZ                            160407 
 3323.00                GO TO 6490-EXIT                                                   160407 
 3324.00            END-IF.                                                               160407 
 3325.00       *                                                                          160407 
 3326.00       * Setup next read of LEXT logical                                          160407 
 3327.00       *                                                                          160407 
 3328.00            MOVE NEXTR                  TO LEXT-FUNCTION.                         160407 
 3329.00       *                                                                          160407 
 3330.00       * We are only interested in vf1 recs                                       160407 
 3331.00       *                                                                          160407 
 3332.00            IF  LEXT-VALIDFLAG        NOT = WSCC-1                                160407 
 3333.00                GO TO 6490-EXIT                                                   160407 
 3334.00            END-IF.                                                               160407 
 3335.00       *                                                                          160407 
 3336.00        6420-READ-T5Z44.                                                          160407 
 3337.00       *                                                                          160407 
 3338.00       * Read T5Z44 using the special term OPCDA                                  160407 
 3339.00       *                                                                          160407 
 3340.00            INITIALIZE                     ITEM-PARAMS                            160407 
 3341.00                                           T5Z44-T5Z44-REC.                       160407 
 3342.00            MOVE SMTP-ITEM              TO ITEM-ITEMPFX.                          160407 
 3343.00            MOVE BPRD-COMPANY           TO ITEM-ITEMCOY.                          160407 
 3344.00            MOVE T5Z44                  TO ITEM-ITEMTABL.                         160407 
 3345.00            MOVE LEXT-OPCDA             TO ITEM-ITEMITEM.                         160407 
 3346.00       *                                                                          160407 
 3347.00            MOVE READR                  TO ITEM-FUNCTION.                         160407 
 3348.00            PERFORM I100-ITEMIO.                                                  160407 
 3349.00       *                                                                          160407 
 3350.00       * If item does not exist then get next LEXT record                         160407 
 3351.00       *                                                                          160407 
 3352.00            IF  ITEM-STATUZ          NOT = O-K                                    160407 
 3353.00                GO TO 6490-EXIT                                                   160407 
 3354.00            END-IF.                                                               160407 
 3355.00       *                                                                          160407 
 3356.00            MOVE ITEM-GENAREA           TO T5Z44-T5Z44-REC.                       160407 
 3357.00       *                                                                          160407 
 3358.00       * If special term category is 0, setup room class from T5Z44               160407 
 3359.00       *                                                                          160407 
 3360.00            IF  T5Z44-ZCONIND            = WSCC-ZERO                              160407 
 3361.00                MOVE T5Z44-CRSTAT       TO ZMDC-ZROOMCL                           160407 
 3362.00                                           ZNGC-ZROOMCL                           160407 
 3363.00            END-IF.                                                               160407 
 3364.00       *                                                                          160407 
 3365.00        6450-STORE-SPTERMS.                                                       160407 
 3366.00       *                                                                          160407 
 3367.00       * Store special terms required to get T7Z37 pricing category               160407 
 3368.00       *                                                                          160407 
 3369.00            SET INVALID-SP-COVR         TO TRUE.                                  160407 
 3370.00       *                                                                          160407 
 3371.00            PERFORM VARYING IX-T7Z38                                              160407 
 3372.00              FROM  1                   BY 1                                      160407 
 3373.00              UNTIL IX-T7Z38             > IX-T7Z38-MAX                           160407 
 3374.00              OR    VALID-SP-COVR                                                 160407 
 3375.00                IF  LEXT-OPCDA           = T7Z38-ZROOMCLS(IX-T7Z38)               160407 
 3376.00                    MOVE LEXT-OPCDA     TO WSAA-RCLASS                            160407 
 3377.00                    SET VALID-SP-COVR   TO TRUE                                   160407 
 3378.00                END-IF                                                            160407 
 3379.00                IF  LEXT-OPCDA           = T7Z38-ZCOINCR(IX-T7Z38)                160407 
 3380.00                    MOVE LEXT-OPCDA     TO WSAA-COINS                             160407 
 3381.00                    SET VALID-SP-COVR   TO TRUE                                   160407 
 3382.00                END-IF                                                            160407 
 3383.00                IF  LEXT-OPCDA           = T7Z38-ZDEDUCTB(IX-T7Z38)               160407 
 3384.00                    MOVE LEXT-OPCDA     TO WSAA-DEDUCT                            160407 
 3385.00                    SET VALID-SP-COVR   TO TRUE                                   160407 
 3386.00                END-IF                                                            160407 
 3387.00            END-PERFORM.                                                          160407 
 3388.00       *                                                                          160407 
 3389.00        6490-EXIT.                                                                160407 
 3390.00             EXIT.                                                                160407 
 3391.00       /                                                                          160407 
 3392.00        6500-PACKAGE-CODE SECTION.                                                160407 
 3393.00       ***************************                                                160407 
 3394.00        6510-START.                                                               160407 
 3395.00       *                                                                          160407 
 3396.00       * If Mednet coverage code not setup from T5Z48 then exit                   160407 
 3397.00       *                                                                          160407 
 3398.00            IF  WSAA-WORK-CRCODE         = SPACES                                 160407 
 3399.00                GO TO 6590-EXIT                                                   160407 
 3400.00            END-IF.                                                               160407 
 3401.00       *                                                                          160407 
 3402.00       * Read T6Z33 using the coverage code and pricing category                  160407 
 3403.00       * in order to get the package codes (if item exists).                      160407 
 3404.00       *                                                                          160407 
 3405.00            INITIALIZE                     ITEM-PARAMS                            160407 
 3406.00                                           T6Z33-T6Z33-REC.                       160407 
 3407.00            MOVE SMTP-ITEM              TO ITEM-ITEMPFX.                          160407 
 3408.00            MOVE BPRD-COMPANY           TO ITEM-ITEMCOY.                          160407 
 3409.00            MOVE T6Z33                  TO ITEM-ITEMTABL.                         160407 
 3410.00            MOVE WSAA-WORK-CRCODE       TO WSCC-CRTABLE-T6Z33.                    160407 
 3411.00            MOVE WSAA-WORK-CAT-SP       TO WSCC-T6Z33-CAT-SP.                     160407 
 3412.00            MOVE WSCC-COVERAGE-T6Z33    TO ITEM-ITEMITEM.                         160407 
 3413.00       *                                                                          160407 
 3414.00            MOVE READR                  TO ITEM-FUNCTION.                         160407 
 3415.00            PERFORM I100-ITEMIO.                                                  160407 
 3416.00       *                                                                          160407 
 3417.00            IF  ITEM-STATUZ          NOT = O-K                                    160407 
 3418.00                GO TO 6590-EXIT                                                   160407 
 3419.00            END-IF                                                                160407 
 3420.00       *                                                                          160407 
 3421.00            MOVE ITEM-GENAREA           TO T6Z33-T6Z33-REC.                       160407 
 3422.00       *                                                                          160407 
 3423.00       * Item exists so setup the package code (1st occurrence)                   160407 
 3424.00       *                                                                          160407 
 3425.00            MOVE T6Z33-JFIELDA-01       TO ZMDC-ZPACKCOD                          160407 
 3426.00                                           ZNGC-ZPACKCOD.                         160407 
 3427.00       *                                                                          160407 
 3428.00        6550-SPECIAL-CASE.                                                        160407 
 3429.00       *                                                                          160407 
 3430.00       * Special processing for Orange Easy whereby we check for                  160407 
 3431.00       * particular clauses. If found, setup package code from 2nd occ.           160407 
 3432.00       *                                                                          160407 
 3433.00            IF  WSAA-WORK-CRCODE     NOT = 'HRC1'                                 160407 
 3434.00                GO TO 6590-EXIT                                                   160407 
 3435.00            END-IF.                                                               160407 
 3436.00       *                                                                          160407 
 3437.00            SET CLAUSE-NOT-FOUND        TO TRUE.                                  160407 
 3438.00       *                                                                          160407 
 3439.00            MOVE ZMDC-ZPOLICY(1:8)      TO WSAA-JCTX-CHDRNUM.                     160411 
 3440.00            MOVE SPACES                 TO WSAA-JCTX-LIFE.                        160407 
 3441.00            MOVE SPACES                 TO WSAA-JCTX-COVERAGE.                    160407 
 3442.00            MOVE SPACES                 TO WSAA-JCTX-RIDER.                       160407 
 3443.00       *                                                                          160407 
 3444.00            INITIALIZE                     JCTX-PARAMS                            160407 
 3445.00                                           JCTXREC-KEY-DATA.                      160407 
 3446.00            MOVE BSPR-COMPANY           TO JCTX-JENTCOY.                          160407 
 3447.00            MOVE WSCC-CM                TO JCTX-JENTITYP.                         160407 
 3448.00            MOVE WSAA-JCTX-ENTITY       TO JCTX-JENTCD.                           160407 
 3449.00            MOVE BEGN                   TO JCTX-FUNCTION.                         160407 
 3450.00            MOVE O-K                    TO JCTX-STATUZ.                           160407 
 3451.00       *                                                                          160407 
 3452.00            PERFORM 6600-PROCESS-JCTX                                             160407 
 3453.00              UNTIL JCTX-STATUZ          = ENDP.                                  160407 
 3454.00       *                                                                          160407 
 3455.00            IF  CLAUSE-FOUND                                                      160407 
 3456.00                MOVE SPACES             TO ZMDC-ZPACKCOD                          160407 
 3457.00                                           ZNGC-ZPACKCOD                          160407 
 3458.00                MOVE T6Z33-JFIELDA-02   TO ZMDC-ZPACKCOD                          160407 
 3459.00                                           ZNGC-ZPACKCOD                          160407 
 3460.00            END-IF.                                                               160407 
 3461.00       *                                                                          160407 
 3462.00        6590-EXIT.                                                                160407 
 3463.00             EXIT.                                                                160407 
 3464.00       /                                                                          160407 
 3465.00        6600-PROCESS-JCTX SECTION.                                                160407 
 3466.00       ***************************                                                160407 
 3467.00        6610-START.                                                               160407 
 3468.00       *                                                                          160407 
 3469.00            PERFORM J200-JCTXIO.                                                  160407 
 3470.00       *                                                                          160407 
 3471.00       * If eof or change of key then exit loop processing                        160407 
 3472.00       *                                                                          160407 
 3473.00            IF  JCTX-STATUZ              = ENDP                                   160407 
 3474.00            OR  JCTX-JENTCOY         NOT = BSPR-COMPANY                           160407 
 3475.00            OR  JCTX-JENTITYP        NOT = WSCC-CM                                160407 
 3476.00            OR  JCTX-JENTCD(1:8)     NOT = WSAA-JCTX-CHDRNUM                      160407 
 3477.00                MOVE ENDP               TO JCTX-STATUZ                            160407 
 3478.00                GO TO 6690-EXIT                                                   160407 
 3479.00            END-IF.                                                               160407 
 3480.00       *                                                                          160407 
 3481.00       * Setup next read of JCTX logical                                          160407 
 3482.00       *                                                                          160407 
 3483.00            MOVE NEXTR                  TO JCTX-FUNCTION.                         160407 
 3484.00       *                                                                          160407 
 3485.00       * We are only interested in sequence no 1 clauses                          160407 
 3486.00       *                                                                          160407 
 3487.00            IF  JCTX-SEQNUMB         NOT = WSCC-1                                 160407 
 3488.00                GO TO 6690-EXIT                                                   160407 
 3489.00            END-IF.                                                               160407 
 3490.00       *                                                                          160407 
 3491.00       * We are only interested STC6131, STC6132, STC6134 codes.                  160407 
 3492.00       * If found, set ind to true and end loop processing.                       160407 
 3493.00       *                                                                          160407 
 3494.00            IF  JCTX-JCLAUSEID           = WSCC-STC6131                           160407 
 3495.00            OR  JCTX-JCLAUSEID           = WSCC-STC6132                           160407 
 3496.00            OR  JCTX-JCLAUSEID           = WSCC-STC6134                           160407 
 3497.00                SET CLAUSE-FOUND        TO TRUE                                   160407 
 3498.00                MOVE ENDP               TO JCTX-STATUZ                            160407 
 3499.00                GO TO 6690-EXIT                                                   160407 
 3500.00            END-IF.                                                               160407 
 3501.00       *                                                                          160407 
 3502.00        6690-EXIT.                                                                160407 
 3503.00            EXIT.                                                                 160407 
 3504.00       /                                                                          160407 
 3505.00        6700-DETERMINE-ZMDC-ZTRNTYP SECTION.                                      160407 
 3506.00       *************************************                                      160407 
 3507.00        6710-START.                                                               160407 
 3508.00       *                                                                          160407 
 3509.00       * ZNGP POLICY DETAILS                                                      160407 
 3510.00       * ===================                                                      160407 
 3511.00       * 01 = Initial Policy                                                      160407 
 3512.00       * 10 = Policy Cancellation                                                 160407 
 3513.00       * 20 = Policy Reactivation                                                 160407 
 3514.00       * 30 = Policy Correction                                                   160407 
 3515.00       *                                                                          160407 
 3516.00       * ZNGC MEMBER DETAILS                                                      160407 
 3517.00       * ===================                                                      160407 
 3518.00       * 01 = Initial Policy                                                      160407 
 3519.00       * 40 = Member Cancellation                                                 160407 
 3520.00       * 41 = Member Reactivation                                                 160407 
 3521.00       * 42 = Member Addition                                                     160407 
 3522.00       * 43 = Member Correction                                                   160407 
 3523.00       *                                                                          160407 
 3524.00       * Default 43 to tran type (Member Correction)                              160407 
 3525.00       *                                                                          160407 
 3526.00            MOVE SPACES             TO WSAA-TRAN-TYP                              160916 
 3527.00            MOVE WSCC-MODIF         TO WSAA-TRAN-TYP                              160916 
 3528.00            PERFORM 17000-READ-T9Z20                                              160916 
 3529.00            MOVE T9Z20-ZTRNTYP(2)   TO WSAA-WORK-ZTRNTYP.                         160916 
 3530.00                                                                                  160916 
 3531.00       ***  MOVE WSCC-43                TO WSAA-WORK-ZTRNTYP.                     160916 
 3532.00       *                                                                          160407 
 3533.00       * If policy we are processing is no longer inforce then we                 160407 
 3534.00       * set the tran type to 40 (Member Cancellation).                           160407 
 3535.00       *                                                                          160407 
 3536.00            IF  NOT CONTRACT-INFORCE                                              160411 
 3537.00                MOVE SPACES             TO WSAA-TRAN-TYP                          160916 
 3538.00                MOVE WSCC-CANCL         TO WSAA-TRAN-TYP                          160916 
 3539.00                PERFORM 17000-READ-T9Z20                                          160916 
 3540.00                MOVE T9Z20-ZTRNTYP(2)   TO WSAA-WORK-ZTRNTYP                      160916 
 3541.00       ***      MOVE WSCC-40            TO WSAA-WORK-ZTRNTYP                      160916 
 3542.00                GO TO 6790-EXIT                                                   160407 
 3543.00            END-IF.                                                               160407 
 3544.00       *                                                                          160407 
 3545.00       * If we reach this point then our policy is inforce.                       160407 
 3546.00       * If no ZNGC exists for policy then this is an initial                     160407 
 3547.00       * transaction so set tran type to 01 (Initial policy)                      160407 
 3548.00       *                                                                          160407 
 3549.00            IF  ZNGC-NOT-FOUND                                                    160407 
 3550.00                MOVE SPACES             TO WSAA-TRAN-TYP                          160916 
 3551.00                MOVE WSCC-NEW           TO WSAA-TRAN-TYP                          160916 
 3552.00                PERFORM 17000-READ-T9Z20                                          160916 
 3553.00                MOVE T9Z20-ZTRNTYP(2)   TO WSAA-WORK-ZTRNTYP                      160916 
 3554.00       ****     MOVE WSCC-01            TO WSAA-WORK-ZTRNTYP                      160916 
 3555.00                GO TO 6790-EXIT                                                   160407 
 3556.00            END-IF.                                                               160407 
 3557.00       *                                                                          160407 
 3558.00       * If we reach this point then our policy is inforce and                    160407 
 3559.00       * we have alreacy created ZNGC recs for this policy.                       160407 
 3560.00       * We now check if an ZNGC rec already exists for this life                 160407 
 3561.00       * member. If not, then we set tran type to 42 (Addition)                   160407 
 3562.00       *                                                                          160407 
 3563.00            IF  MEMBER-NOT-FOUND                                                  160407 
 3564.00                MOVE SPACES             TO WSAA-TRAN-TYP                          160916 
 3565.00                MOVE WSCC-ADD           TO WSAA-TRAN-TYP                          160916 
 3566.00                PERFORM 17000-READ-T9Z20                                          160916 
 3567.00                MOVE T9Z20-ZTRNTYP(2)   TO WSAA-WORK-ZTRNTYP                      160916 
 3568.00       ***      MOVE WSCC-42            TO WSAA-WORK-ZTRNTYP                      160916 
 3569.00                GO TO 6790-EXIT                                                   160407 
 3570.00            END-IF.                                                               160407 
 3571.00       *                                                                          160407 
 3572.00       * If we reach this point then our policy is inforce and                    160407 
 3573.00       * we have an ZNGC record for our life member so we set                     160407 
 3574.00       * the tran type to 43 (Member Correction). If reinstating                  160407 
 3575.00       * this policy then tran type will be 41 (Member Reactivation).             160407 
 3576.00       *                                                                          160407 
 3577.00            MOVE WSCC-43                TO WSAA-WORK-ZTRNTYP                      160407 
 3578.00       *                                                                          160407 
 3579.00       * Member Reactivation                                                      160412 
 3580.00       * ===================                                                      160412 
 3581.00       * If original ZNGP had tran type 10 (Policy Cancelled) and the             160412 
 3582.00       * policy status code is now inforce then we set the member                 160412 
 3583.00       * trans type to 41 (Member Reactivation)                                   160412 
 3584.00       *                                                                          160407 
 3585.00            IF  WSAA-ZNGP-ZTRNTYP        = WSCC-10                                160407 
 3586.00       *****************************************************************          160511 
 3587.00       * NOTE - Until further notice we use 43 for Member Reactivation            160511 
 3588.00       *****************************************************************          160511 
 3589.00       ****     MOVE WSCC-41            TO WSAA-WORK-ZTRNTYP                      160511 
 3590.00                MOVE SPACES             TO WSAA-TRAN-TYP                          160916 
 3591.00                MOVE WSCC-REACT         TO WSAA-TRAN-TYP                          160916 
 3592.00                PERFORM 17000-READ-T9Z20                                          160916 
 3593.00                MOVE T9Z20-ZTRNTYP(2)   TO WSAA-WORK-ZTRNTYP                      160916 
 3594.00       ***      MOVE WSCC-43            TO WSAA-WORK-ZTRNTYP                      160916 
 3595.00                GO TO 6790-EXIT                                                   160407 
 3596.00            END-IF.                                                               160407 
 3597.00       *                                                                          160407 
 3598.00        6790-EXIT.                                                                160407 
 3599.00             EXIT.                                                                160407 
 3600.00       /                                                                          160407 
 3601.00        7500-READ-CLAUSES SECTION.                                                160407 
 3602.00       ***************************                                                160407 
 3603.00        7510-START.                                                               160407 
 3604.00       *                                                                          160407 
 3605.00            MOVE COVR-CHDRNUM           TO WSAA-JCLT-CHDRNUM.                     160407 
 3606.00            MOVE COVR-LIFE              TO WSAA-JCLT-LIFE.                        160407 
 3607.00            MOVE COVR-COVERAGE          TO WSAA-JCLT-COVERAGE.                    160407 
 3608.00            MOVE COVR-RIDER             TO WSAA-JCLT-RIDER.                       160407 
 3609.00       *                                                                          160407 
 3610.00       * Read JCLT file to take the Clauses.                                      160407 
 3611.00       *                                                                          160407 
 3612.00            INITIALIZE                     JCLT-PARAMS                            160407 
 3613.00                                           JCLTREC-KEY-DATA                       160407 
 3614.00                                           WSKY-JCLT-KEY.                         160407 
 3615.00            MOVE BSPR-COMPANY           TO JCLT-JENTCOY.                          160407 
 3616.00            MOVE WSCC-CM                TO JCLT-JENTITYP.                         160407 
 3617.00            MOVE WSAA-JCLT-ENTITY       TO JCLT-JENTCD.                           160407 
 3618.00            MOVE JCLT-DATA-KEY          TO WSKY-JCLT-KEY.                         160407 
 3619.00            MOVE BEGN                   TO JCLT-FUNCTION.                         160407 
 3620.00            MOVE O-K                    TO JCLT-STATUZ.                           160407 
 3621.00       *                                                                          160407 
 3622.00            PERFORM 7600-CALL-JCLT-IO                                             160407 
 3623.00              UNTIL JCLT-STATUZ          = ENDP.                                  160407 
 3624.00       *                                                                          160407 
 3625.00        7590-EXIT.                                                                160407 
 3626.00             EXIT.                                                                160407 
 3627.00       /                                                                          160407 
 3628.00        7600-CALL-JCLT-IO SECTION.                                                160407 
 3629.00       ***************************                                                160407 
 3630.00        7610-START.                                                               160407 
 3631.00       *                                                                          160407 
 3632.00            PERFORM J100-JCLTIO.                                                  160407 
 3633.00       *                                                                          160407 
 3634.00       * If eof or change of key then exit loop processing                        160407 
 3635.00       *                                                                          160407 
 3636.00            IF  JCLT-STATUZ              = ENDP                                   160407 
 3637.00            OR  JCLT-JENTCOY         NOT = WSKY-JCLT-JENTCOY                      160407 
 3638.00            OR  JCLT-JENTITYP        NOT = WSKY-JCLT-JENTITYP                     160412 
 3639.00            OR  JCLT-JENTCD          NOT = WSKY-JCLT-JENTCD                       160407 
 3640.00                MOVE ENDP               TO JCLT-STATUZ                            160407 
 3641.00                GO TO 7690-EXIT                                                   160407 
 3642.00            END-IF.                                                               160407 
 3643.00       *                                                                          160407 
 3644.00       * Setup next read of JCLT logical                                          160407 
 3645.00       *                                                                          160407 
 3646.00            MOVE NEXTR                  TO JCLT-FUNCTION.                         160407 
 3647.00       *                                                                          160407 
 3648.00       * Read thru the clause text records for this clause entity                 160407 
 3649.00       *                                                                          160407 
 3650.00            INITIALIZE                     JCTX-PARAMS                            160407 
 3651.00                                           JCTXREC-KEY-DATA                       160407 
 3652.00                                           WSKY-JCTX-KEY.                         160407 
 3653.00            MOVE BSPR-COMPANY           TO JCTX-JENTCOY.                          160407 
 3654.00            MOVE WSCC-CM                TO JCTX-JENTITYP.                         160407 
 3655.00            MOVE JCLT-JENTCD            TO JCTX-JENTCD.                           160407 
 3656.00            MOVE JCLT-JCLAUSEID         TO JCTX-JCLAUSEID.                        160407 
 3657.00            MOVE JCTX-DATA-KEY          TO WSKY-JCTX-KEY.                         160407 
 3658.00            MOVE BEGN                   TO JCTX-FUNCTION.                         160407 
 3659.00            MOVE O-K                    TO JCTX-STATUZ.                           160407 
 3660.00       *                                                                          160407 
 3661.00            PERFORM 7700-CALL-JCTX-IO                                             160407 
 3662.00              UNTIL JCTX-STATUZ          = ENDP.                                  160407 
 3663.00       *                                                                          160407 
 3664.00        7690-EXIT.                                                                160407 
 3665.00            EXIT.                                                                 160407 
 3666.00       /                                                                          160407 
 3667.00        7700-CALL-JCTX-IO SECTION.                                                160407 
 3668.00       ***************************                                                160407 
 3669.00        7710-START.                                                               160407 
 3670.00       *                                                                          160407 
 3671.00            PERFORM J200-JCTXIO.                                                  160407 
 3672.00       *                                                                          160407 
 3673.00       * If eof or change of key then exit loop processing                        160407 
 3674.00       *                                                                          160407 
 3675.00            IF  JCTX-STATUZ              = ENDP                                   160407 
 3676.00            OR  JCTX-JENTCOY         NOT = WSKY-JCTX-JENTCOY                      160407 
 3677.00            OR  JCTX-JENTITYP        NOT = WSKY-JCTX-JENTITYP                     160407 
 3678.00            OR  JCTX-JENTCD          NOT = WSKY-JCTX-JENTCD                       160412 
 3679.00            OR  JCTX-JCLAUSEID       NOT = WSKY-JCTX-JCLAUSEID                    160407 
 3680.00                MOVE ENDP               TO JCTX-STATUZ                            160407 
 3681.00                GO TO 7790-EXIT                                                   160407 
 3682.00            END-IF.                                                               160407 
 3683.00       *                                                                          160407 
 3684.00       * Setup next read of JCTX logical                                          160407 
 3685.00       *                                                                          160407 
 3686.00            MOVE NEXTR                  TO JCTX-FUNCTION.                         160407 
 3687.00       *                                                                          160407 
 3688.00       * Read table T6Z03 for Special Clauses. If the Item                        160407 
 3689.00       * exists then move the Item to JCTX file, if not exists                    160407 
 3690.00       * move the Decription of the Item.                                         160407 
 3691.00       *                                                                          160407 
 3692.00            IF  JCTX-SEQNUMB             = 1                                      160407 
 3693.00                MOVE JCLT-CURRFROM      TO WSAA-DATCON1-DATE                      160412 
 3694.00                MOVE SPACES             TO WSAA-DESC-DATE                         160407 
 3695.00                MOVE 'JCLT-FROM'        TO WSAA-DESC-DATE                         160407 
 3696.00                PERFORM 16000-CONVERT-DATE                                        160407 
 3697.00                MOVE 10                 TO IY-TABLE                               160407 
 3698.00                ADD  10                 TO WSAA-IY                                160407 
 3699.00                IF  IX-TABLE             > 1900                                   160407 
 3700.00                    GO TO 7790-EXIT                                               160407 
 3701.00                END-IF                                                            160407 
 3702.00                MOVE COVR-CRTABLE       TO ZMDN-WORK-AREA-DATA                    160407 
 3703.00                                           (IX-TABLE:IY-TABLE)                    160407 
 3704.00                MOVE COVR-CRTABLE       TO ZNGN-WORK-AREA-DATA                    160407 
 3705.00                                           (IX-TABLE:IY-TABLE)                    160407 
 3706.00                ADD 2                   TO WSAA-IY                                160407 
 3707.00                MOVE WSAA-IY            TO IX-TABLE                               160407 
 3708.00                MOVE 10                 TO IY-TABLE                               160407 
 3709.00                ADD 10                  TO WSAA-IY                                160407 
 3710.00                IF  IX-TABLE             > 1900                                   160407 
 3711.00                    GO TO 7790-EXIT                                               160407 
 3712.00                END-IF                                                            160407 
 3713.00                MOVE DTC1-EXT-DATE      TO ZMDN-WORK-AREA-DATA                    160407 
 3714.00                                           (IX-TABLE:IY-TABLE)                    160407 
 3715.00                MOVE DTC1-EXT-DATE      TO ZNGN-WORK-AREA-DATA                    160407 
 3716.00                                           (IX-TABLE:IY-TABLE)                    160407 
 3717.00                ADD 2                   TO WSAA-IY                                160407 
 3718.00                MOVE WSAA-IY            TO IX-TABLE                               160407 
 3719.00       *                                                                          160407 
 3720.00       * Move the Current To from JCLT  to work-area                              160407 
 3721.00       * Convert the "date from"  to right format (DD/MM/YYYY)                    160407 
 3722.00       *                                                                          160407 
 3723.00                MOVE JCLT-CURRTO        TO WSAA-DATCON1-DATE                      160412 
 3724.00                MOVE SPACES             TO WSAA-DESC-DATE                         160407 
 3725.00                MOVE 'JCLT-TO'          TO WSAA-DESC-DATE                         160407 
 3726.00                PERFORM 16000-CONVERT-DATE                                        160407 
 3727.00                MOVE 10                 TO IY-TABLE                               160407 
 3728.00                ADD 10                  TO WSAA-IY                                160407 
 3729.00                IF  IX-TABLE             > 1900                                   160407 
 3730.00                    GO TO 7790-EXIT                                               160407 
 3731.00                END-IF                                                            160407 
 3732.00                IF  DTC1-EXT-DATE        = SPACES                                 160407 
 3733.00                    MOVE JCLT-CURRTO    TO ZMDN-WORK-AREA-DATA                    160407 
 3734.00                                           (IX-TABLE:IY-TABLE)                    160407 
 3735.00                    MOVE JCLT-CURRTO    TO ZNGN-WORK-AREA-DATA                    160407 
 3736.00                                           (IX-TABLE:IY-TABLE)                    160407 
 3737.00                ELSE                                                              160407 
 3738.00                    MOVE DTC1-EXT-DATE  TO ZMDN-WORK-AREA-DATA                    160407 
 3739.00                                           (IX-TABLE:IY-TABLE)                    160407 
 3740.00                    MOVE DTC1-EXT-DATE  TO ZNGN-WORK-AREA-DATA                    160407 
 3741.00                                           (IX-TABLE:IY-TABLE)                    160407 
 3742.00                END-IF                                                            160407 
 3743.00                ADD 2               TO WSAA-IY                                    160407 
 3744.00                MOVE WSAA-IY        TO IX-TABLE                                   160407 
 3745.00            END-IF.                                                               160407 
 3746.00       *                                                                          160407 
 3747.00       * Read T6Z03 Table to  check if we must send the decrtiption               160407 
 3748.00       * or the Code in Work Area.                                                160407 
 3749.00       *                                                                          160407 
 3750.00            PERFORM 7800-READ-T6Z03.                                              160407 
 3751.00       *                                                                          160407 
 3752.00            IF  ITEM-STATUZ              = O-K                                    160407 
 3753.00                IF  JCTX-SEQNUMB         = 1                                      160407 
 3754.00                    MOVE 7              TO IY-TABLE                               160407 
 3755.00                    ADD 7               TO WSAA-IY                                160407 
 3756.00                    IF  IX-TABLE         > 1900                                   160407 
 3757.00                        GO TO 7790-EXIT                                           160407 
 3758.00                    END-IF                                                        160407 
 3759.00                    MOVE JCTX-JCLAUSEID TO ZMDN-WORK-AREA-DATA                    160407 
 3760.00                                           (IX-TABLE:IY-TABLE)                    160407 
 3761.00                    MOVE JCTX-JCLAUSEID TO ZNGN-WORK-AREA-DATA                    160407 
 3762.00                                           (IX-TABLE:IY-TABLE)                    160407 
 3763.00                    ADD 2               TO WSAA-IY                                160407 
 3764.00                    MOVE WSAA-IY        TO IX-TABLE                               160407 
 3765.00                ELSE                                                              160407 
 3766.00                    GO TO 7790-EXIT                                               160407 
 3767.00                END-IF                                                            160407 
 3768.00            ELSE                                                                  160407 
 3769.00                MOVE 70                 TO IY-TABLE                               160407 
 3770.00                ADD 70                  TO WSAA-IY                                160407 
 3771.00                IF  IX-TABLE             > 1900                                   160407 
 3772.00                    GO TO 7790-EXIT                                               160407 
 3773.00                END-IF                                                            160407 
 3774.00                MOVE JCTX-TXTLINE       TO ZMDN-WORK-AREA-DATA                    160407 
 3775.00                                           (IX-TABLE:IY-TABLE)                    160407 
 3776.00                MOVE JCTX-TXTLINE       TO ZNGN-WORK-AREA-DATA                    160407 
 3777.00                                           (IX-TABLE:IY-TABLE)                    160407 
 3778.00                ADD 2                   TO WSAA-IY                                160407 
 3779.00                MOVE WSAA-IY            TO IX-TABLE                               160407 
 3780.00            END-IF.                                                               160407 
 3781.00       *                                                                          160407 
 3782.00        7790-EXIT.                                                                160407 
 3783.00            EXIT.                                                                 160407 
 3784.00       /                                                                          160407 
 3785.00        7800-READ-T6Z03 SECTION.                                                  160407 
 3786.00       *************************                                                  160407 
 3787.00        7810-START.                                                               160407 
 3788.00       *                                                                          160407 
 3789.00            INITIALIZE                     ITEM-PARAMS.                           160407 
 3790.00            MOVE SMTP-ITEM              TO ITEM-ITEMPFX.                          160407 
 3791.00            MOVE BPRD-COMPANY           TO ITEM-ITEMCOY.                          160407 
 3792.00            MOVE T6Z03                  TO ITEM-ITEMTABL.                         160407 
 3793.00            MOVE JCTX-JCLAUSEID         TO ITEM-ITEMITEM.                         160407 
 3794.00       *                                                                          160407 
 3795.00            MOVE READR                  TO ITEM-FUNCTION.                         160407 
 3796.00            PERFORM I100-ITEMIO.                                                  160407 
 3797.00       *                                                                          160407 
 3798.00        7890-EXIT.                                                                160407 
 3799.00             EXIT.                                                                160407 
 3800.00       /                                                                          160407 
 3801.00        8000-MODIFICATION-ON-CLIENT SECTION.                                      160408 
 3802.00       *************************************                                      160407 
 3803.00        8010-START.                                                               160408 
 3804.00       *                                                                          160407 
 3805.00            MOVE O-K                    TO WSAA-SQL-STAT.                         160408 
 3806.00       *                                                                          160408 
 3807.00       * For client processing, we initialize particular w/s fields               160408 
 3808.00       * so that extract processing will work accordingly.                        160408 
 3809.00       *                                                                          160408 
 3810.00            MOVE SPACES                 TO WS88-BATCTRCDE.                        160408 
 3811.00            MOVE ZEROES                 TO WSAA-WORK-EFFDATE.                     160408 
 3812.00       *                                                                          160407 
 3813.00       * Setup SQL statement                                                      160407 
 3814.00       *                                                                          160407 
 3815.00            EXEC SQL                                                              160408 
 3816.00               DECLARE CLNTDAT1 CURSOR FOR                                        160408 
 3817.00                 SELECT CLNTPFX                                                   160408 
 3818.00                       ,CLNTCOY                                                   160408 
 3819.00                       ,CLNTNUM                                                   160408 
 3820.00                       ,DATIME                                                    160408 
 3821.00                 FROM CLNTPF                                                      160408 
 3822.00                 ORDER BY DATIME DESC                                             160408 
 3823.00            END-EXEC.                                                             160408 
 3824.00       *                                                                          160407 
 3825.00       * Open the cursor (this runs the query)                                    160407 
 3826.00       *                                                                          160407 
 3827.00            EXEC SQL                                                              160408 
 3828.00               OPEN CLNTDAT1                                                      160408 
 3829.00            END-EXEC.                                                             160408 
 3830.00       *                                                                          160407 
 3831.00        8020-READ-CLNTDAT.                                                        160408 
 3832.00       *                                                                          160408 
 3833.00       * Fetch Record                                                             160408 
 3834.00       *                                                                          160408 
 3835.00            EXEC SQL                                                              160408 
 3836.00               WHENEVER SQLERROR GO TO 500-SQL-ERROR                              160408 
 3837.00            END-EXEC.                                                             160408 
 3838.00       *                                                                          160408 
 3839.00            EXEC SQL                                                              160408 
 3840.00              WHENEVER NOT FOUND GO TO 8050-END-OF-FILE                           160408 
 3841.00            END-EXEC.                                                             160408 
 3842.00       *                                                                          160408 
 3843.00            EXEC SQL                                                              160408 
 3844.00              FETCH CLNTDAT1 INTO :CLNTREC1                                       160408 
 3845.00            END-EXEC.                                                             160408 
 3846.00       *                                                                          160408 
 3847.00       * CT11 - Total CLNT records read                                           160408 
 3848.00       *                                                                          160408 
 3849.00            MOVE CT11                   TO CONT-TOTNO.                            160408 
 3850.00            MOVE 1                      TO CONT-TOTVAL.                           160408 
 3851.00            PERFORM 001-CALL-CONTOT.                                              160408 
 3852.00       *                                                                          160407 
 3853.00       * Setup client record date                                                 160407 
 3854.00       *                                                                          160407 
 3855.00            MOVE SQL-DATIME             TO WSAA-DATIME.                           160408 
 3856.00            MOVE WSAA-DATIME-YEAR       TO WSAA-CLNT-YEAR.                        160408 
 3857.00            MOVE WSAA-DATIME-MONTH      TO WSAA-CLNT-MONTH.                       160408 
 3858.00            MOVE WSAA-DATIME-DAY        TO WSAA-CLNT-DAY.                         160408 
 3859.00       *                                                                          160407 
 3860.00       * We are only interested in client changes which have been                 160408 
 3861.00       * made after the last MEDNET extract date. As our SQL statement            160408 
 3862.00       * is sorted by DATIME ascending, if we reach client record                 160408 
 3863.00       * where the last change date is <= last MEDNET extract date                160408 
 3864.00       * then we stop processing.                                                 160408 
 3865.00       *                                                                          160408 
 3866.00            IF  WSAA-CLNT-DATE          <= WSAA-DATAREA-DATE                      160408 
 3867.00                GO TO 8050-END-OF-FILE                                            160408 
 3868.00            END-IF.                                                               160408 
 3869.00       *                                                                          160408 
 3870.00       * We have a client record with a change date > dataarea date               160408 
 3871.00       * so now we check if the change date <= batch effdate. If not              160408 
 3872.00       * we get the next CLNT record.                                             160408 
 3873.00       *                                                                          160408 
 3874.00            IF  WSAA-CLNT-DATE           > BSSC-EFFECTIVE-DATE                    160408 
 3875.00                GO TO 8020-READ-CLNTDAT                                           160408 
 3876.00            END-IF.                                                               160408 
 3877.00       *                                                                          160408 
 3878.00       * CT12 - Total CLNT records selected                                       160412 
 3879.00       *                                                                          160408 
 3880.00            MOVE CT12                   TO CONT-TOTNO.                            160408 
 3881.00            MOVE 1                      TO CONT-TOTVAL.                           160408 
 3882.00            PERFORM 001-CALL-CONTOT.                                              160408 
 3883.00       *                                                                          160407 
 3884.00       * Get client CCS no                                                        160407 
 3885.00       *                                                                          160407 
 3886.00            MOVE SQL-CLNTNUM            TO WSAA-WORK-CLNTNUM.                     160408 
 3887.00            PERFORM 11000-GET-CCSNO.                                              160408 
 3888.00       *                                                                          160427 
 3889.00       * If no CC role exists for client no selected then get next                160427 
 3890.00       *                                                                          160427 
 3891.00            IF  CC-ROLE-NOT-FOUND                                                 160427 
 3892.00                GO TO 8020-READ-CLNTDAT                                           160427 
 3893.00            END-IF.                                                               160427 
 3894.00       *                                                                          160408 
 3895.00       * Valid CLNTDAT record found so we read thru ZNGCs for the                 160408 
 3896.00       * relevant client to check if MEDNET record exist. If so, then             160408 
 3897.00       * we process all contracts for the particular client.                      160408 
 3898.00       *                                                                          160408 
 3899.00            MOVE WSAA-CLEAN-CCSNO       TO WSAA-WORK-ZLFCODE.                     160408 
 3900.00            PERFORM 9000-PROCESS-CHANGES.                                         160408 
 3901.00       *                                                                          160407 
 3902.00       * Go back to get next client record                                        160407 
 3903.00       *                                                                          160407 
 3904.00            GO TO 8020-READ-CLNTDAT.                                              160408 
 3905.00       *                                                                          160407 
 3906.00        8050-END-OF-FILE.                                                         160408 
 3907.00       *                                                                          160407 
 3908.00            EXEC SQL                                                              160408 
 3909.00               CLOSE CLNTDAT1                                                     160408 
 3910.00            END-EXEC.                                                             160408 
 3911.00       *                                                                          160407 
 3912.00        8090-EXIT.                                                                160408 
 3913.00            EXIT.                                                                 160408 
 3914.00       /                                                                          160408 
 3915.00        8500-CHECK-FOR-IBAN SECTION.                                              160408 
 3916.00       *****************************                                              160408 
 3917.00        8510-START.                                                               160408 
 3918.00       *                                                                          160408 
 3919.00       * Setup read of LPELCMP3 logical (From dataarea date onwards)              160411 
 3920.00       *                                                                          160408 
 3921.00            MOVE WSAA-DATAREA-YEAR      TO P8DATY OF LPELCMP3.                    160411 
 3922.00            MOVE WSAA-DATAREA-MONTH     TO P8DATM OF LPELCMP3.                    160411 
 3923.00            MOVE WSAA-DATAREA-DAY       TO P8DATD OF LPELCMP3.                    160411 
 3924.00       *                                                                          160411 
 3925.00       * Setup read to start of logical file LPELCMP3                             160411 
 3926.00       *                                                                          160411 
 3927.00            START LPELCMP3          KEY >= LPELCMP3-KEY.                          160411 
 3928.00       *                                                                          160408 
 3929.00            PERFORM 8600-PROCESS-LPELCMP3                                         160408 
 3930.00              UNTIL LPELCMP3-STATUS  NOT = FOUND3-REC.                            160408 
 3931.00       *                                                                          160408 
 3932.00        8590-EXIT.                                                                160408 
 3933.00            EXIT.                                                                 160408 
 3934.00       /                                                                          160408 
 3935.00        8600-PROCESS-LPELCMP3 SECTION.                                            160408 
 3936.00       *******************************                                            160408 
 3937.00        8610-START.                                                               160408 
 3938.00       *                                                                          160408 
 3939.00       * Read the LPELCMP3 and find if any record exist between                   160408 
 3940.00       * these two dates.                                                         160408 
 3941.00       *                                                                          160408 
 3942.00            READ LPELCMP3 NEXT.                                                   160512 
 3943.00       *                                                                          160408 
 3944.00       * If eof then exit loop processing                                         160408 
 3945.00       *                                                                          160408 
 3946.00            IF  LPELCMP3-STATUS      NOT = FOUND3-REC                             160408 
 3947.00                GO TO 8690-EXIT                                                   160408 
 3948.00            END-IF.                                                               160408 
 3949.00       *                                                                          160408 
 3950.00       * CT14 - Total IBAN records read                                           160412 
 3951.00       *                                                                          160408 
 3952.00            MOVE CT14                   TO CONT-TOTNO.                            160412 
 3953.00            MOVE 1                      TO CONT-TOTVAL.                           160408 
 3954.00            PERFORM 001-CALL-CONTOT.                                              160408 
 3955.00       *                                                                          160408 
 3956.00       * For each record we setup effdate in format YYYYMMDD                      160408 
 3957.00       *                                                                          160408 
 3958.00            MOVE P8DATY OF LPELCMP3     TO WSAA-IBAN-YEAR.                        160408 
 3959.00            MOVE P8DATM OF LPELCMP3     TO WSAA-IBAN-MONTH.                       160408 
 3960.00            MOVE P8DATD OF LPELCMP3     TO WSAA-IBAN-DAY.                         160408 
 3961.00       *                                                                          160408 
 3962.00       * We are only interested in IBAN changes which have been                   160408 
 3963.00       * made after the last MEDNET extract date otherwise we get                 160408 
 3964.00       * the next LPELCMP3 record                                                 160408 
 3965.00       *                                                                          160408 
 3966.00            IF  WSAA-IBAN-EFFDATE       <= WSAA-DATAREA-DATE                      160408 
 3967.00                GO TO 8690-EXIT                                                   160408 
 3968.00            END-IF.                                                               160408 
 3969.00       *                                                                          160408 
 3970.00       * We have an IBAN record with a change date > dataarea date                160408 
 3971.00       * so now we check if the change date <= batch effdate. If not              160408 
 3972.00       * we get the next LPELCMP3 record.                                         160408 
 3973.00       *                                                                          160408 
 3974.00            IF  WSAA-IBAN-EFFDATE        > BSSC-EFFECTIVE-DATE                    160408 
 3975.00                GO TO 8690-EXIT                                                   160408 
 3976.00            END-IF.                                                               160408 
 3977.00       *                                                                          160408 
 3978.00       * CT15 - Total IBAN records selected                                       160412 
 3979.00       *                                                                          160408 
 3980.00            MOVE CT15                   TO CONT-TOTNO.                            160412 
 3981.00            MOVE 1                      TO CONT-TOTVAL.                           160408 
 3982.00            PERFORM 001-CALL-CONTOT.                                              160408 
 3983.00       *                                                                          160408 
 3984.00       * Valid LPELCMP3 record found so we read thru ZNGCs for the                160408 
 3985.00       * relevant client to check if MEDNET record exist. If so, then             160408 
 3986.00       * we process all contracts for the particular client.                      160408 
 3987.00       *                                                                          160408 
 3988.00            MOVE P8CUS OF LPELCMP3      TO WSAA-REP-ZEROES.                       160411 
 3989.00            PERFORM 12000-REPLACE-ZEROES.                                         160411 
 3990.00            MOVE WSAA-REP-ZEROES        TO WSAA-WORK-ZLFCODE.                     160411 
 3991.00       *                                                                          160411 
 3992.00            PERFORM 9000-PROCESS-CHANGES.                                         160411 
 3993.00       *                                                                          160408 
 3994.00        8690-EXIT.                                                                160408 
 3995.00            EXIT.                                                                 160408 
 3996.00       /                                                                          160408 
 3997.00        9000-PROCESS-CHANGES SECTION.                                             160408 
 3998.00       ******************************                                             160408 
 3999.00        9010-START.                                                               160408 
 4000.00       *                                                                          160408 
 4001.00            INITIALIZE                     IV                                     160408 
 4002.00                                           IW                                     160408 
 4003.00                                           WSAA-CHDRNUM-ARRAY.                    160408 
 4004.00       *                                                                          160408 
 4005.00            INITIALIZE                     ZNGCCLN-PARAMS                         160408 
 4006.00                                           WSKY-ZNGCCLN-KEY.                      160408 
 4007.00            MOVE WSAA-WORK-ZLFCODE      TO ZNGCCLN-ZLFCODE.                       160408 
 4008.00            MOVE ZNGCCLN-DATA-KEY       TO WSKY-ZNGCCLN-KEY.                      160408 
 4009.00            MOVE BEGN                   TO ZNGCCLN-FUNCTION.                      160408 
 4010.00            MOVE O-K                    TO ZNGCCLN-STATUZ.                        160408 
 4011.00       *                                                                          160408 
 4012.00            PERFORM 9100-CHECK-ZNGCCLN                                            160408 
 4013.00              UNTIL ZNGCCLN-STATUZ       = ENDP.                                  160408 
 4014.00       *                                                                          160408 
 4015.00       * Store the total no of contracts for this client                          160408 
 4016.00       *                                                                          160408 
 4017.00            MOVE IW                     TO WSAA-TOT-CONTRACTS.                    160408 
 4018.00       *                                                                          160408 
 4019.00       * If no valid ZNGCCLN contracts found then exit                            160408 
 4020.00       *                                                                          160408 
 4021.00            IF  WSAA-TOT-CONTRACTS       = 0                                      160408 
 4022.00                GO TO 9090-EXIT                                                   160408 
 4023.00            END-IF.                                                               160408 
 4024.00       *                                                                          160408 
 4025.00       * Read thru all contracts for this client which are stored in              160408 
 4026.00       * the contract w/s table and perform extract processing                    160408 
 4027.00       *                                                                          160408 
 4028.00            PERFORM VARYING IW        FROM 1 BY 1                                 160408 
 4029.00              UNTIL IW                   > WSCC-MAX-CONTRACTS                     160408 
 4030.00                 OR WSAA-CHDRNUM(IW)     = SPACES                                 160408 
 4031.00               PERFORM 9200-PROCESS-CONTRACTS                                     160408 
 4032.00            END-PERFORM.                                                          160408 
 4033.00       *                                                                          160408 
 4034.00        9090-EXIT.                                                                160408 
 4035.00            EXIT.                                                                 160408 
 4036.00       /                                                                          160408 
 4037.00        9100-CHECK-ZNGCCLN SECTION.                                               160408 
 4038.00       ****************************                                               160408 
 4039.00        9110-START.                                                               160408 
 4040.00       *                                                                          160408 
 4041.00            PERFORM N400-ZNGCCLNIO.                                               160408 
 4042.00       *                                                                          160408 
 4043.00       * If eof or change of key then exit loop processing                        160408 
 4044.00       *                                                                          160408 
 4045.00            IF  ZNGCCLN-STATUZ           = ENDP                                   160408 
 4046.00            OR  ZNGCCLN-ZLFCODE      NOT = WSKY-ZNGCCLN-ZLFCODE                   160408 
 4047.00                MOVE ENDP               TO ZNGCCLN-STATUZ                         160408 
 4048.00                GO TO 9190-EXIT                                                   160408 
 4049.00            END-IF.                                                               160408 
 4050.00       *                                                                          160408 
 4051.00       * Setup next read of ZNGCCLN logical                                       160408 
 4052.00       *                                                                          160408 
 4053.00            MOVE NEXTR                  TO ZNGCCLN-FUNCTION.                      160408 
 4054.00       *                                                                          160408 
 4055.00       * If X-Ref is spaces then field ZPOLICY contains the client no             160408 
 4056.00       * in which case we get the next ZNGCCLN record                             160408 
 4057.00       *                                                                          160408 
 4058.00            IF  ZNGCCLN-JXREFNUM         = SPACES                                 160408 
 4059.00                GO TO 9190-EXIT                                                   160408 
 4060.00            END-IF.                                                               160408 
 4061.00       *                                                                          160411 
 4062.00       * Check that contract no is within parameter range (if entered)            160411 
 4063.00       * else get next ZNGCCLN                                                    160411 
 4064.00       *                                                                          160411 
 4065.00            IF  ZNGCCLN-ZPOLICY(1:8)     < WSAA-CHDRNUM-FROM                      160411 
 4066.00            OR  ZNGCCLN-ZPOLICY(1:8)     > WSAA-CHDRNUM-TO                        160411 
 4067.00                GO TO 9190-EXIT                                                   160411 
 4068.00            END-IF.                                                               160411 
 4069.00       *                                                                          160408 
 4070.00       * We have zn ZNGCCLN for the client so check that the                      160408 
 4071.00       * cancellation date is not spaces otherwise get next record                160408 
 4072.00       *                                                                          160408 
 4073.00            IF  ZNGCCLN-ZCANDTE      NOT = SPACES                                 160408 
 4074.00                GO TO 9190-EXIT                                                   160408 
 4075.00            END-IF.                                                               160408 
 4076.00       *                                                                          160408 
 4077.00       * Check if this contract no is already in our w/s table                    160408 
 4078.00       *                                                                          160408 
 4079.00            SET CONTRACT-NOT-FOUND      TO TRUE.                                  160408 
 4080.00       *                                                                          160408 
 4081.00            PERFORM VARYING IV        FROM 1 BY 1                                 160408 
 4082.00              UNTIL IV                   > WSCC-MAX-CONTRACTS                     160408 
 4083.00                 OR CONTRACT-FOUND                                                160408 
 4084.00              IF  ZNGCCLN-ZPOLICY(1:8)   = WSAA-CHDRNUM(IV)                       160411 
 4085.00                  SET CONTRACT-FOUND    TO TRUE                                   160408 
 4086.00              END-IF                                                              160408 
 4087.00            END-PERFORM.                                                          160408 
 4088.00       *                                                                          160408 
 4089.00       * If contract already in w/s table then get next ZNGCCLN rec               160408 
 4090.00       *                                                                          160408 
 4091.00            IF  CONTRACT-FOUND                                                    160408 
 4092.00                GO TO 9190-EXIT                                                   160408 
 4093.00            END-IF.                                                               160408 
 4094.00       *                                                                          160408 
 4095.00       * Contract not found in w/s table so set it up                             160408 
 4096.00       *                                                                          160408 
 4097.00            ADD  1                      TO IW.                                    160408 
 4098.00       *                                                                          160408 
 4099.00            MOVE ZNGCCLN-ZPOLICY(1:8)   TO WSAA-CHDRNUM(IW).                      160408 
 4100.00       *                                                                          160412 
 4101.00       * CT13 - Total CLNT Change Contracts Selected                              160412 
 4102.00       *                                                                          160412 
 4103.00            IF  CLNT-PROCESS-ACTIVE                                               160412 
 4104.00                MOVE CT13                   TO CONT-TOTNO                         160412 
 4105.00                MOVE 1                      TO CONT-TOTVAL                        160412 
 4106.00                PERFORM 001-CALL-CONTOT                                           160412 
 4107.00            END-IF.                                                               160412 
 4108.00       *                                                                          160412 
 4109.00       * CT16 - Total IBAN Change Contracts Selected                              160412 
 4110.00       *                                                                          160412 
 4111.00            IF  IBAN-PROCESS-ACTIVE                                               160412 
 4112.00                MOVE CT16                   TO CONT-TOTNO                         160412 
 4113.00                MOVE 1                      TO CONT-TOTVAL                        160412 
 4114.00                PERFORM 001-CALL-CONTOT                                           160412 
 4115.00            END-IF.                                                               160412 
 4116.00       *                                                                          160408 
 4117.00        9190-EXIT.                                                                160408 
 4118.00            EXIT.                                                                 160408 
 4119.00       /                                                                          160408 
 4120.00        9200-PROCESS-CONTRACTS SECTION.                                           160408 
 4121.00       ********************************                                           160408 
 4122.00        9210-START.                                                               160408 
 4123.00       *                                                                          160408 
 4124.00       * Get contract & agent details                                             160408 
 4125.00       *                                                                          160408 
 4126.00            MOVE WSAA-CHDRNUM(IW)       TO WSAA-WORK-CHDRNUM.                     160408 
 4127.00       *                                                                          160408 
 4128.00            PERFORM 3200-READ-CHDRINP.                                            160408 
 4129.00            IF DONT-PROCESS-RECORD                                                160913 
 4130.00               GO TO 9290-EXIT                                                    160913 
 4131.00            END-IF                                                                160913 
 4132.00            PERFORM 3300-READ-ZCHAFLG.                                            160408 
 4133.00       *                                                                          160408 
 4134.00       * For Client/IBAN changes, we only process inforce contracts               160411 
 4135.00       *                                                                          160408 
 4136.00            IF  NOT CONTRACT-INFORCE                                              160411 
 4137.00                GO TO 9290-EXIT                                                   160411 
 4138.00            END-IF.                                                               160411 
 4139.00       *                                                                          160411 
 4140.00       * Check rules                                                              160411 
 4141.00       *                                                                          160411 
 4142.00            PERFORM 3400-CHECK-RULES.                                             160411 
 4143.00       *                                                                          160408 
 4144.00       * If record is not allowed for some reason then get next                   160408 
 4145.00       *                                                                          160408 
 4146.00            IF  DONT-PROCESS-RECORD                                               160408 
 4147.00                GO TO 9290-EXIT                                                   160408 
 4148.00            END-IF.                                                               160408 
 4149.00       *                                                                          160408 
 4150.00       * Find the main life & all valid lives for the contract                    160408 
 4151.00       *                                                                          160408 
 4152.00            PERFORM 3700-CHECK-LIVES.                                             160408 
 4153.00       *                                                                          160408 
 4154.00       * If contract has no lives for some reason then get next PTRN              160408 
 4155.00       *                                                                          160408 
 4156.00            IF  WSAA-TOT-LIVES           = 0                                      160408 
 4157.00                GO TO 9290-EXIT                                                   160408 
 4158.00            END-IF.                                                               160408 
 4159.00       *                                                                          160408 
 4160.00       * Create new MEDNET and ING Policy, Member & Note details                  160408 
 4161.00       * for this contract (if not already created via PTRN process).             160408 
 4162.00       *                                                                          160408 
 4163.00            PERFORM 5000-EXTRACT-DETAILS.                                         160411 
 4164.00       *                                                                          160408 
 4165.00        9290-EXIT.                                                                160408 
 4166.00            EXIT.                                                                 160408 
 4167.00       /                                                                          160407 
 4168.00        10000-READ-CLNT SECTION.                                                  160407 
 4169.00       *************************                                                  160407 
 4170.00        10010-START.                                                              160407 
 4171.00       *                                                                          160407 
 4172.00            INITIALIZE                     CLNT-PARAMS.                           160407 
 4173.00            MOVE PRFX-CLNT              TO CLNT-CLNTPFX.                          160407 
 4174.00            MOVE BSPR-FSUCO             TO CLNT-CLNTCOY.                          160407 
 4175.00            MOVE WSAA-WORK-CLNTNUM      TO CLNT-CLNTNUM.                          160412 
 4176.00            MOVE CLNTREC                TO CLNT-FORMAT.                           160407 
 4177.00            MOVE READR                  TO CLNT-FUNCTION                          160407 
 4178.00       *                                                                          160407 
 4179.00            CALL 'CLNTIO'            USING CLNT-PARAMS.                           160407 
 4180.00       *                                                                          160407 
 4181.00            IF  CLNT-STATUZ          NOT = O-K                                    160407 
 4182.00                MOVE CLNT-PARAMS        TO SYSR-PARAMS                            160407 
 4183.00                MOVE CLNT-STATUZ        TO SYSR-STATUZ                            160407 
 4184.00                PERFORM 600-FATAL-ERROR                                           160407 
 4185.00            END-IF.                                                               160407 
 4186.00       *                                                                          160407 
 4187.00        10090-EXIT.                                                               160407 
 4188.00            EXIT.                                                                 160407 
 4189.00       /                                                                          160407 
 4190.00        11000-GET-CCSNO SECTION.                                                  160407 
 4191.00       *************************                                                  160407 
 4192.00        11010-START.                                                              160407 
 4193.00       *                                                                          160407 
 4194.00            SET CC-ROLE-NOT-FOUND       TO TRUE.                                  160427 
 4195.00       *                                                                          160427 
 4196.00            INITIALIZE                     CLRRWIN-PARAMS                         160407 
 4197.00                                           WSKY-CLRRWIN-KEY                       160408 
 4198.00                                           WSAA-WORK-CCSNO                        160408 
 4199.00                                           WSAA-CLEAN-CCSNO.                      160408 
 4200.00            MOVE BSPR-FSUCO             TO CLRRWIN-FORECOY.                       160407 
 4201.00            MOVE WSAA-WORK-CLNTNUM      TO CLRRWIN-CLNTNUM.                       160407 
 4202.00            MOVE WSCC-CC                TO CLRRWIN-CLRRROLE.                      160407 
 4203.00            MOVE CLRRWIN-DATA-KEY       TO WSKY-CLRRWIN-KEY.                      160408 
 4204.00            MOVE CLRRWINREC             TO CLRRWIN-FORMAT.                        160407 
 4205.00            MOVE BEGN                   TO CLRRWIN-FUNCTION.                      160407 
 4206.00       *                                                                          160407 
 4207.00            CALL 'CLRRWINIO'         USING CLRRWIN-PARAMS.                        160407 
 4208.00       *                                                                          160407 
 4209.00            IF  CLRRWIN-STATUZ           = O-K                                    160427 
 4210.00            AND CLRRWIN-FORECOY          = WSKY-CLRRWIN-FORECOY                   160427 
 4211.00            AND CLRRWIN-CLNTNUM          = WSKY-CLRRWIN-CLNTNUM                   160427 
 4212.00            AND CLRRWIN-CLRRROLE         = WSKY-CLRRWIN-CLRRROLE                  160427 
 4213.00                SET CC-ROLE-FOUND       TO TRUE                                   160427 
 4214.00            END-IF.                                                               160407 
 4215.00       *                                                                          160427 
 4216.00       * If client change processing is active and we do not find                 160427 
 4217.00       * a CC role for the client no which was selected then this                 160427 
 4218.00       * is not an error as it could be an alternate address. In                  160427 
 4219.00       * such a case we exit                                                      160427 
 4220.00       *                                                                          160427 
 4221.00            IF  CLNT-PROCESS-ACTIVE                                               160427 
 4222.00            AND CC-ROLE-NOT-FOUND                                                 160427 
 4223.00                GO TO 11090-EXIT                                                  160427 
 4224.00            END-IF.                                                               160427 
 4225.00       *                                                                          160427 
 4226.00       * In all other cases if CC role is not found then bomb                     160427 
 4227.00       *                                                                          160427 
 4228.00            IF  CC-ROLE-NOT-FOUND                                                 160427 
 4229.00                MOVE CLRRWIN-STATUZ     TO SYSR-STATUZ                            160427 
 4230.00                MOVE WSKY-CLRRWIN-KEY   TO CLRRWIN-DATA-KEY                       160427 
 4231.00                MOVE CLRRWIN-PARAMS     TO SYSR-PARAMS                            160427 
 4232.00                PERFORM 600-FATAL-ERROR                                           160427 
 4233.00            END-IF.                                                               160427 
 4234.00       *                                                                          160407 
 4235.00            MOVE CLRRWIN-FORENUM        TO WSAA-WORK-CCSNO.                       160407 
 4236.00       *                                                                          160407 
 4237.00       * Also get CCS no with leading spaces instead of zeroes                    160407 
 4238.00       *                                                                          160407 
 4239.00            MOVE WSAA-WORK-CCSNO        TO WSAA-REP-ZEROES.                       160407 
 4240.00            PERFORM 12000-REPLACE-ZEROES.                                         160407 
 4241.00            MOVE WSAA-REP-ZEROES        TO WSAA-CLEAN-CCSNO.                      160407 
 4242.00       *                                                                          160407 
 4243.00        11090-EXIT.                                                               160407 
 4244.00            EXIT.                                                                 160407 
 4245.00       /                                                                          160407 
 4246.00        12000-REPLACE-ZEROES SECTION.                                             160407 
 4247.00       ******************************                                             160407 
 4248.00        12010-START.                                                              160407 
 4249.00       *                                                                          160407 
 4250.00            PERFORM VARYING IU        FROM 1 BY 1                                 160408 
 4251.00              UNTIL IU                   > 8                                      160408 
 4252.00               IF  WSAA-REP-ZERO(IU)     = WSCC-ZERO                              160408 
 4253.00                   MOVE SPACES          TO WSAA-REP-ZERO(IU)                      160408 
 4254.00               ELSE                                                               160407 
 4255.00                   MOVE 16              TO IU                                     160408 
 4256.00               END-IF                                                             160407 
 4257.00            END-PERFORM.                                                          160407 
 4258.00       *                                                                          160407 
 4259.00        12090-EXIT.                                                               160407 
 4260.00             EXIT.                                                                160407 
 4261.00       /                                                                          160407 
 4262.00        13000-READ-T5Z48 SECTION.                                                 160407 
 4263.00       **************************                                                 160407 
 4264.00        13010-START.                                                              160407 
 4265.00       *                                                                          160407 
 4266.00       **** INITIALIZE                     ITEM-PARAMS.                  <ATHC60> 180601 
 4267.00       **** MOVE SMTP-ITEM              TO ITEM-ITEMPFX.                 <ATHC60> 180601 
 4268.00       **** MOVE BSPR-COMPANY           TO ITEM-ITEMCOY.                 <ATHC60> 180601 
 4269.00       **** MOVE T5Z48                  TO ITEM-ITEMTABL.                <ATHC60> 180601 
 4270.00       **** MOVE WSAA-WORK-CRTABLE      TO WSCC-CRTABLE-72.              <ATHC60> 180601 
 4271.00       **** MOVE WSCC-COVERAGE-72       TO ITEM-ITEMITEM.                <ATHC60> 180601 
 4272.00       ****                                                              <ATHC60> 180601 
 4273.00       **** MOVE READR                  TO ITEM-FUNCTION.                <ATHC60> 180601 
 4274.00       **** PERFORM I100-ITEMIO.                                         <ATHC60> 180601 
 4275.00       ****                                                              <ATHC60> 180601 
 4276.00       **** IF  ITEM-STATUZ              = O-K                           <ATHC60> 180601 
 4277.00       ****     MOVE ITEM-GENAREA       TO T5Z48-T5Z48-REC               <ATHC60> 180601 
 4278.00       **** END-IF.                                                      <ATHC60> 180601 
 4279.00                                                                         <ATHC60> 180601 
 4280.00            PERFORM 13050-FIND-RENEWAL-DATE                              <ATHC60> 180601 
 4281.00                                                                         <ATHC60> 180601 
 4282.00            INITIALIZE ITDM-PARAMS                                       <ATHC60> 180601 
 4283.00            INITIALIZE ITEMREC-KEY-DATA     OF ITDM-PARAMS               <ATHC60> 180601 
 4284.00            INITIALIZE ITEMREC-NON-KEY-DATA OF ITDM-PARAMS               <ATHC60> 180601 
 4285.00                                                                         <ATHC60> 180601 
 4286.00            MOVE SMTP-ITEM              TO ITDM-ITEMPFX                  <ATHC60> 180601 
 4287.00            MOVE BSPR-COMPANY           TO ITDM-ITEMCOY                  <ATHC60> 180601 
 4288.00            MOVE T5Z48                  TO ITDM-ITEMTABL                 <ATHC60> 180601 
 4289.00            MOVE WSAA-USE-AGE-DATE      TO ITDM-ITMFRM                   <ATHC60> 180601 
 4290.00            MOVE WSAA-WORK-CRTABLE      TO WSCC-CRTABLE-72.              <ATHC60> 180601 
 4291.00            MOVE WSCC-COVERAGE-72       TO ITDM-ITEMITEM.                <ATHC60> 180608 
 4292.00            MOVE ITDM-DATA-KEY          TO WSKY-ITDM-KEY                 <ATHC60> 180601 
 4293.00                                                                         <ATHC60> 180601 
 4294.00            MOVE BEGN                   TO ITDM-FUNCTION                 <ATHC60> 180601 
 4295.00                                                                         <ATHC60> 180601 
 4296.00            PERFORM I200-ITDMIO                                          <ATHC60> 180601 
 4297.00                                                                         <ATHC60> 180601 
 4298.00            IF  ITDM-STATUZ        = O-K                                 <ATHC60> 180601 
 4299.00            AND ITDM-ITEMCOY       = WSKY-ITDM-ITEMCOY                   <ATHC60> 180601 
 4300.00            AND ITDM-ITEMTABL      = WSKY-ITDM-ITEMTABL                  <ATHC60> 180601 
 4301.00            AND ITDM-ITEMITEM      = WSKY-ITDM-ITEMITEM                  <ATHC60> 180601 
 4302.00                MOVE ITDM-GENAREA       TO T5Z48-T5Z48-REC               <ATHC60> 180601 
 4303.00            ELSE                                                         <ATHC60> 180613 
 4304.00                MOVE ENDP               TO ITDM-STATUZ                   <ATHC60> 180613 
 4305.00            END-IF                                                       <ATHC60> 180601 
 4306.00            .                                                            <ATHC60> 180601 
 4307.00       *                                                                          160407 
 4308.00        13090-EXIT.                                                               160407 
 4309.00             EXIT.                                                                160407 
 4310.00       /                                                                          160407 
 4311.00        13050-FIND-RENEWAL-DATE SECTION.                                 <ATHC60> 180601 
 4312.00       ********************************                                  <ATHC60> 180601 
 4313.00        13050-START.                                                     <ATHC60> 180601 
 4314.00                                                                         <ATHC60> 180601 
 4315.00            MOVE ZEROS                  TO WSAA-USE-AGE-DATE             <ATHC60> 180601 
 4316.00            COMPUTE WSAA-DATCON2-FOR     = WSCC-NUM--1                   <ATHC60> 180601 
 4317.00            END-COMPUTE                                                  <ATHC60> 180601 
 4318.00                                                                         <ATHC60> 180612 
 4319.00            IF  WSAA-RERATE-FROM-DATE = ZEROS                            <ATHC60> 180612 
 4320.00            OR  WSAA-RERATE-FROM-DATE = VRCM-MAX-DATE                    <ATHC60> 180612 
 4321.00                MOVE BSSC-EFFECTIVE-DATE                                 <ATHC60> 180612 
 4322.00                                        TO WSAA-DATCON2-FROM-DATE        <ATHC60> 180612 
 4323.00            ELSE                                                         <ATHC60> 180612 
 4324.00                MOVE WSAA-RERATE-FROM-DATE                               <ATHC60> 180612 
 4325.00                                        TO WSAA-DATCON2-FROM-DATE        <ATHC60> 180612 
 4326.00            END-IF                                                       <ATHC60> 180612 
 4327.00                                                                         <ATHC60> 180612 
 4328.00            MOVE FREQ-YRLY              TO WSAA-DATCON2-FREQ             <ATHC60> 180601 
 4329.00                                                                         <ATHC60> 180601 
 4330.00            PERFORM X600-CALL-DATCON2                                    <ATHC60> 180601 
 4331.00                                                                         <ATHC60> 180601 
 4332.00            MOVE WSAA-DATCON2-DATE      TO WSAA-USE-AGE-DATE             <ATHC60> 180601 
 4333.00            .                                                            <ATHC60> 180601 
 4334.00        13050-EXIT.                                                      <ATHC60> 180601 
 4335.00            EXIT.                                                        <ATHC60> 180601 
 4336.00                                                                         <ATHC60> 180601 
 4337.00        15000-DELETE-SEQ-ZEROES SECTION.                                          160407 
 4338.00       *********************************                                          160407 
 4339.00        15100-START.                                                              160407 
 4340.00       *                                                                          160407 
 4341.00            MOVE WSAA-SEQNUM            TO WSAA-SEQ-NUMBERS.                      160407 
 4342.00       *                                                                          160407 
 4343.00            PERFORM VARYING WSAA-SUB  FROM 1 BY 1                                 160407 
 4344.00              UNTIL WSAA-SUB             > 15                                     160407 
 4345.00               IF  WSAA-SEQ-NUMBER(WSAA-SUB)                                      160407 
 4346.00                                         = WSCC-ZERO                              160407 
 4347.00                   MOVE SPACES          TO                                        160407 
 4348.00                                          WSAA-SEQ-NUMBER(WSAA-SUB)               160407 
 4349.00               ELSE                                                               160407 
 4350.00                   MOVE 16              TO WSAA-SUB                               160407 
 4351.00               END-IF                                                             160407 
 4352.00            END-PERFORM.                                                          160407 
 4353.00       *                                                                          160407 
 4354.00        15090-EXIT.                                                               160407 
 4355.00             EXIT.                                                                160407 
 4356.00       /                                                                          160407 
 4357.00        16000-CONVERT-DATE SECTION.                                               160407 
 4358.00       ****************************                                               160407 
 4359.00        16010-START.                                                              160407 
 4360.00       *                                                                          160407 
 4361.00            INITIALIZE                     DTC1-DATCON1-REC.                      160407 
 4362.00            MOVE CONV                   TO DTC1-FUNCTION                          160407 
 4363.00            MOVE WSAA-DATCON1-DATE      TO DTC1-INT-DATE.                         160412 
 4364.00       *                                                                          160407 
 4365.00            CALL 'DATCON1'           USING DTC1-DATCON1-REC                       160407 
 4366.00       *                                                                          160407 
 4367.00            IF  DTC1-STATUZ          NOT = O-K                                    160407 
 4368.00                STRING WSAA-WORK-CHDRNUM DELIMITED BY SIZE,                       160407 
 4369.00                '-'                      DELIMITED BY SIZE,                       160407 
 4370.00                WSAA-WORK-CLNTNUM        DELIMITED  BY SIZE,                      160407 
 4371.00                '-'                      DELIMITED BY SIZE,                       160407 
 4372.00                WSAA-DESC-DATE           DELIMITED  BY SPACE,                     160407 
 4373.00                '-'                      DELIMITED BY SIZE,                       160407 
 4374.00                DTC1-DATCON1-REC         DELIMITED BY SIZE                        160407 
 4375.00                                         INTO SYSR-PARAMS                         160407 
 4376.00                MOVE DTC1-STATUZ        TO SYSR-STATUZ                            160407 
 4377.00                PERFORM 600-FATAL-ERROR                                           160407 
 4378.00            END-IF.                                                               160407 
 4379.00       *                                                                          160407 
 4380.00        16090-EXIT.                                                               160407 
 4381.00             EXIT.                                                                160407 
 4382.00       /                                                                          160916 
 4383.00        17000-READ-T9Z20 SECTION.                                                 160916 
 4384.00       **************************                                                 160916 
 4385.00        17010-START.                                                              160916 
 4386.00       *                                                                          160916 
 4387.00            INITIALIZE                     ITEM-PARAMS.                           160916 
 4388.00            MOVE SMTP-ITEM              TO ITEM-ITEMPFX.                          160916 
 4389.00            MOVE BSPR-COMPANY           TO ITEM-ITEMCOY.                          160916 
 4390.00            MOVE T9Z20                  TO ITEM-ITEMTABL.                         160916 
 4391.00            MOVE WSAA-TRAN-TYP          TO ITEM-ITEMITEM.                         160916 
 4392.00       *                                                                          160916 
 4393.00            MOVE READR                  TO ITEM-FUNCTION.                         160916 
 4394.00            PERFORM I100-ITEMIO.                                                  160916 
 4395.00       *                                                                          160916 
 4396.00            IF  ITEM-STATUZ              = O-K                                    160916 
 4397.00                MOVE ITEM-GENAREA       TO T9Z20-T9Z20-REC                        160916 
 4398.00            END-IF.                                                               160916 
 4399.00       *                                                                          160916 
 4400.00        17090-EXIT.                                                               160916 
 4401.00             EXIT.                                                                160916 
 4402.00       /                                                                          160407 
 4403.00        I100-ITEMIO SECTION.                                                      160407 
 4404.00       *********************                                                      160407 
 4405.00        I110-START.                                                               160407 
 4406.00       *                                                                          160407 
 4407.00            MOVE O-K                    TO ITEM-STATUZ.                           160407 
 4408.00            MOVE ITEMREC                TO ITEM-FORMAT.                           160407 
 4409.00       *                                                                          160407 
 4410.00            CALL 'ITEMIO'            USING ITEM-PARAMS.                           160407 
 4411.00       *                                                                          160407 
 4412.00            EVALUATE TRUE                                                         160407 
 4413.00             WHEN ITEM-STATUZ            = O-K                                    160407 
 4414.00                  CONTINUE                                                        160407 
 4415.00             WHEN ITEM-FUNCTION          = READR                                  160407 
 4416.00              AND ITEM-STATUZ            = MRNF                                   160407 
 4417.00                  CONTINUE                                                        160407 
 4418.00             WHEN OTHER                                                           160407 
 4419.00                  MOVE ITEM-STATUZ      TO SYSR-STATUZ                            160407 
 4420.00                  MOVE ITEM-PARAMS      TO SYSR-PARAMS                            160407 
 4421.00                  PERFORM 600-FATAL-ERROR                                         160407 
 4422.00            END-EVALUATE.                                                         160407 
 4423.00       *                                                                          160407 
 4424.00        I190-EXIT.                                                                160407 
 4425.00             EXIT.                                                                160407 
 4426.00       /                                                                          160407 
 4427.00        I200-ITDMIO SECTION.                                                      160407 
 4428.00       *********************                                                      160407 
 4429.00        I210-START.                                                               160407 
 4430.00       *                                                                          160407 
 4431.00            MOVE O-K                    TO ITDM-STATUZ.                           160407 
 4432.00            MOVE ITDMREC                TO ITDM-FORMAT.                           160407 
 4433.00       *                                                                          160407 
 4434.00            CALL 'ITDMIO'            USING ITDM-PARAMS.                           160407 
 4435.00       *                                                                          160407 
 4436.00            EVALUATE TRUE                                                         160407 
 4437.00             WHEN ITDM-STATUZ            = O-K                                    160407 
 4438.00                  CONTINUE                                                        160407 
 4439.00             WHEN ITDM-FUNCTION          = BEGN                                   160407 
 4440.00              AND ITDM-STATUZ            = ENDP                                   160407 
 4441.00                  CONTINUE                                                        160407 
 4442.00             WHEN OTHER                                                           160407 
 4443.00                  MOVE ITDM-STATUZ      TO SYSR-STATUZ                            160407 
 4444.00                  MOVE ITDM-PARAMS      TO SYSR-PARAMS                            160407 
 4445.00                  PERFORM 600-FATAL-ERROR                                         160407 
 4446.00            END-EVALUATE.                                                         160407 
 4447.00       *                                                                          160407 
 4448.00        I290-EXIT.                                                                160407 
 4449.00             EXIT.                                                                160407 
 4450.00       /                                                                          160407 
 4451.00        J100-JCLTIO SECTION.                                                      160407 
 4452.00       *********************                                                      160407 
 4453.00        J110-START.                                                               160407 
 4454.00       *                                                                          160407 
 4455.00            MOVE O-K                    TO JCLT-STATUZ.                           160407 
 4456.00            MOVE JCLTREC                TO JCLT-FORMAT.                           160407 
 4457.00       *                                                                          160407 
 4458.00            CALL 'JCLTIO'            USING JCLT-PARAMS.                           160407 
 4459.00       *                                                                          160407 
 4460.00            EVALUATE TRUE                                                         160407 
 4461.00             WHEN JCLT-STATUZ            = O-K                                    160407 
 4462.00                  CONTINUE                                                        160407 
 4463.00             WHEN JCLT-FUNCTION          = BEGN                                   160407 
 4464.00              AND JCLT-STATUZ            = ENDP                                   160407 
 4465.00                  CONTINUE                                                        160407 
 4466.00             WHEN JCLT-FUNCTION          = NEXTR                                  160407 
 4467.00              AND JCLT-STATUZ            = ENDP                                   160407 
 4468.00                  CONTINUE                                                        160407 
 4469.00             WHEN OTHER                                                           160407 
 4470.00                  MOVE JCLT-STATUZ      TO SYSR-STATUZ                            160407 
 4471.00                  MOVE JCLT-PARAMS      TO SYSR-PARAMS                            160407 
 4472.00                  PERFORM 600-FATAL-ERROR                                         160407 
 4473.00            END-EVALUATE.                                                         160407 
 4474.00       *                                                                          160407 
 4475.00        J190-EXIT.                                                                160407 
 4476.00             EXIT.                                                                160407 
 4477.00       /                                                                          160407 
 4478.00        J200-JCTXIO SECTION.                                                      160407 
 4479.00       *********************                                                      160407 
 4480.00        J210-START.                                                               160407 
 4481.00       *                                                                          160407 
 4482.00            MOVE O-K                    TO JCTX-STATUZ.                           160407 
 4483.00            MOVE JCTXREC                TO JCTX-FORMAT.                           160407 
 4484.00       *                                                                          160407 
 4485.00            CALL 'JCTXIO'            USING JCTX-PARAMS.                           160407 
 4486.00       *                                                                          160407 
 4487.00            EVALUATE TRUE                                                         160407 
 4488.00             WHEN JCTX-STATUZ            = O-K                                    160407 
 4489.00                  CONTINUE                                                        160407 
 4490.00             WHEN JCTX-FUNCTION          = BEGN                                   160407 
 4491.00              AND JCTX-STATUZ            = ENDP                                   160407 
 4492.00                  CONTINUE                                                        160407 
 4493.00             WHEN JCTX-FUNCTION          = NEXTR                                  160407 
 4494.00              AND JCTX-STATUZ            = ENDP                                   160407 
 4495.00                  CONTINUE                                                        160407 
 4496.00             WHEN OTHER                                                           160407 
 4497.00                  MOVE JCTX-STATUZ      TO SYSR-STATUZ                            160407 
 4498.00                  MOVE JCTX-PARAMS      TO SYSR-PARAMS                            160407 
 4499.00                  PERFORM 600-FATAL-ERROR                                         160407 
 4500.00            END-EVALUATE.                                                         160407 
 4501.00       *                                                                          160407 
 4502.00        J290-EXIT.                                                                160407 
 4503.00             EXIT.                                                                160407 
 4504.00       /                                                                          160407 
 4505.00        M100-ZMDPIO SECTION.                                                      160407 
 4506.00       *********************                                                      160407 
 4507.00        M110-START.                                                               160407 
 4508.00       *                                                                          160407 
 4509.00            MOVE O-K                    TO ZMDP-STATUZ.                           160407 
 4510.00            MOVE ZMDPREC                TO ZMDP-FORMAT.                           160407 
 4511.00       *                                                                          160407 
 4512.00            CALL 'ZMDPIO'            USING ZMDP-PARAMS.                           160407 
 4513.00       *                                                                          160407 
 4514.00            EVALUATE TRUE                                                         160407 
 4515.00             WHEN ZMDP-STATUZ            = O-K                                    160407 
 4516.00                  CONTINUE                                                        160407 
 4517.00             WHEN ZMDP-FUNCTION          = READR                                  160407 
 4518.00              AND ZMDP-STATUZ            = MRNF                                   160407 
 4519.00                  CONTINUE                                                        160407 
 4520.00             WHEN OTHER                                                           160407 
 4521.00                  MOVE ZMDP-STATUZ      TO SYSR-STATUZ                            160407 
 4522.00                  MOVE ZMDP-PARAMS      TO SYSR-PARAMS                            160407 
 4523.00                  PERFORM 600-FATAL-ERROR                                         160407 
 4524.00            END-EVALUATE.                                                         160407 
 4525.00       *                                                                          160407 
 4526.00        M190-EXIT.                                                                160407 
 4527.00             EXIT.                                                                160407 
 4528.00       /                                                                          160407 
 4529.00        M200-ZMDCIO SECTION.                                                      160407 
 4530.00       *********************                                                      160407 
 4531.00        M210-START.                                                               160407 
 4532.00       *                                                                          160407 
 4533.00            MOVE O-K                    TO ZMDC-STATUZ.                           160407 
 4534.00            MOVE ZMDCREC                TO ZMDC-FORMAT.                           160407 
 4535.00       *                                                                          160407 
 4536.00            CALL 'ZMDCIO'            USING ZMDC-PARAMS.                           160407 
 4537.00       *                                                                          160407 
 4538.00            EVALUATE TRUE                                                         160407 
 4539.00             WHEN ZMDC-STATUZ            = O-K                                    160407 
 4540.00                  CONTINUE                                                        160407 
 4541.00             WHEN OTHER                                                           160407 
 4542.00                  MOVE ZMDC-STATUZ      TO SYSR-STATUZ                            160407 
 4543.00                  MOVE ZMDC-PARAMS      TO SYSR-PARAMS                            160407 
 4544.00                  PERFORM 600-FATAL-ERROR                                         160407 
 4545.00            END-EVALUATE.                                                         160407 
 4546.00       *                                                                          160407 
 4547.00        M290-EXIT.                                                                160407 
 4548.00             EXIT.                                                                160407 
 4549.00       /                                                                          160407 
 4550.00        M300-ZMDNIO SECTION.                                                      160407 
 4551.00       *********************                                                      160407 
 4552.00        M310-START.                                                               160407 
 4553.00       *                                                                          160407 
 4554.00            MOVE O-K                    TO ZMDN-STATUZ.                           160407 
 4555.00            MOVE ZMDNREC                TO ZMDN-FORMAT.                           160407 
 4556.00       *                                                                          160407 
 4557.00            CALL 'ZMDNIO'            USING ZMDN-PARAMS.                           160407 
 4558.00       *                                                                          160407 
 4559.00            EVALUATE TRUE                                                         160407 
 4560.00             WHEN ZMDN-STATUZ            = O-K                                    160407 
 4561.00                  CONTINUE                                                        160407 
 4562.00             WHEN OTHER                                                           160407 
 4563.00                  MOVE ZMDN-STATUZ      TO SYSR-STATUZ                            160407 
 4564.00                  MOVE ZMDN-PARAMS      TO SYSR-PARAMS                            160407 
 4565.00                  PERFORM 600-FATAL-ERROR                                         160407 
 4566.00            END-EVALUATE.                                                         160407 
 4567.00       *                                                                          160407 
 4568.00        M390-EXIT.                                                                160407 
 4569.00             EXIT.                                                                160407 
 4570.00       /                                                                          160407 
 4571.00        N100-ZNGPIO SECTION.                                                      160407 
 4572.00       *********************                                                      160407 
 4573.00        N110-START.                                                               160407 
 4574.00       *                                                                          160407 
 4575.00            MOVE O-K                    TO ZNGP-STATUZ.                           160407 
 4576.00            MOVE ZNGPREC                TO ZNGP-FORMAT.                           160407 
 4577.00       *                                                                          160407 
 4578.00            CALL 'ZNGPIO'            USING ZNGP-PARAMS.                           160407 
 4579.00       *                                                                          160407 
 4580.00            EVALUATE TRUE                                                         160407 
 4581.00             WHEN ZNGP-STATUZ            = O-K                                    160407 
 4582.00                  CONTINUE                                                        160407 
 4583.00             WHEN ZNGP-FUNCTION          = READR                                  160407 
 4584.00              AND ZNGP-STATUZ            = MRNF                                   160407 
 4585.00                  CONTINUE                                                        160407 
 4586.00             WHEN OTHER                                                           160407 
 4587.00                  MOVE ZNGP-STATUZ      TO SYSR-STATUZ                            160407 
 4588.00                  MOVE ZNGP-PARAMS      TO SYSR-PARAMS                            160407 
 4589.00                  PERFORM 600-FATAL-ERROR                                         160407 
 4590.00            END-EVALUATE.                                                         160407 
 4591.00       *                                                                          160407 
 4592.00        N190-EXIT.                                                                160407 
 4593.00             EXIT.                                                                160407 
 4594.00       /                                                                          160407 
 4595.00        N200-ZNGCIO SECTION.                                                      160407 
 4596.00       *********************                                                      160407 
 4597.00        N210-START.                                                               160407 
 4598.00       *                                                                          160407 
 4599.00            MOVE O-K                    TO ZNGC-STATUZ.                           160407 
 4600.00            MOVE ZNGCREC                TO ZNGC-FORMAT.                           160407 
 4601.00       *                                                                          160407 
 4602.00            CALL 'ZNGCIO'            USING ZNGC-PARAMS.                           160407 
 4603.00       *                                                                          160407 
 4604.00            EVALUATE TRUE                                                         160407 
 4605.00             WHEN ZNGC-STATUZ            = O-K                                    160407 
 4606.00                  CONTINUE                                                        160407 
 4607.00             WHEN ZNGC-FUNCTION          = BEGNH                                  160407 
 4608.00              AND ZNGC-STATUZ            = ENDP                                   160407 
 4609.00                  CONTINUE                                                        160407 
 4610.00             WHEN ZNGC-FUNCTION          = NEXTR                                  160407 
 4611.00              AND ZNGC-STATUZ            = ENDP                                   160407 
 4612.00                  CONTINUE                                                        160407 
 4613.00             WHEN OTHER                                                           160407 
 4614.00                  MOVE ZNGC-STATUZ      TO SYSR-STATUZ                            160407 
 4615.00                  MOVE ZNGC-PARAMS      TO SYSR-PARAMS                            160407 
 4616.00                  PERFORM 600-FATAL-ERROR                                         160407 
 4617.00            END-EVALUATE.                                                         160407 
 4618.00       *                                                                          160407 
 4619.00        N290-EXIT.                                                                160407 
 4620.00             EXIT.                                                                160407 
 4621.00       /                                                                          160407 
 4622.00        N300-ZNGNIO SECTION.                                                      160407 
 4623.00       *********************                                                      160407 
 4624.00        N310-START.                                                               160407 
 4625.00       *                                                                          160407 
 4626.00            MOVE O-K                    TO ZNGN-STATUZ.                           160407 
 4627.00            MOVE ZNGNREC                TO ZNGN-FORMAT.                           160407 
 4628.00       *                                                                          160407 
 4629.00            CALL 'ZNGNIO'            USING ZNGN-PARAMS.                           160407 
 4630.00       *                                                                          160407 
 4631.00            EVALUATE TRUE                                                         160407 
 4632.00             WHEN ZNGN-STATUZ            = O-K                                    160407 
 4633.00                  CONTINUE                                                        160407 
 4634.00             WHEN ZNGN-FUNCTION          = BEGNH                                  160407 
 4635.00              AND ZNGN-STATUZ            = ENDP                                   160407 
 4636.00                  CONTINUE                                                        160407 
 4637.00             WHEN ZNGN-FUNCTION          = NEXTR                                  160407 
 4638.00              AND ZNGN-STATUZ            = ENDP                                   160407 
 4639.00                  CONTINUE                                                        160407 
 4640.00             WHEN OTHER                                                           160407 
 4641.00                  MOVE ZNGN-STATUZ      TO SYSR-STATUZ                            160407 
 4642.00                  MOVE ZNGN-PARAMS      TO SYSR-PARAMS                            160407 
 4643.00                  PERFORM 600-FATAL-ERROR                                         160407 
 4644.00            END-EVALUATE.                                                         160407 
 4645.00       *                                                                          160407 
 4646.00        N390-EXIT.                                                                160407 
 4647.00             EXIT.                                                                160407 
 4648.00       /                                                                          160407 
 4649.00        N400-ZNGCCLNIO SECTION.                                                   160407 
 4650.00       ************************                                                   160407 
 4651.00        N410-START.                                                               160407 
 4652.00       *                                                                          160407 
 4653.00            MOVE O-K                    TO ZNGCCLN-STATUZ.                        160407 
 4654.00            MOVE ZNGCCLNREC             TO ZNGCCLN-FORMAT.                        160407 
 4655.00       *                                                                          160407 
 4656.00            CALL 'ZNGCCLNIO'         USING ZNGCCLN-PARAMS.                        160407 
 4657.00       *                                                                          160407 
 4658.00            EVALUATE TRUE                                                         160407 
 4659.00             WHEN ZNGCCLN-STATUZ         = O-K                                    160407 
 4660.00                  CONTINUE                                                        160407 
 4661.00             WHEN ZNGCCLN-FUNCTION       = BEGN                                   160408 
 4662.00              AND ZNGCCLN-STATUZ         = ENDP                                   160407 
 4663.00                  CONTINUE                                                        160407 
 4664.00             WHEN ZNGCCLN-FUNCTION       = NEXTR                                  160407 
 4665.00              AND ZNGCCLN-STATUZ         = ENDP                                   160407 
 4666.00                  CONTINUE                                                        160407 
 4667.00             WHEN OTHER                                                           160407 
 4668.00                  MOVE ZNGCCLN-STATUZ   TO SYSR-STATUZ                            160407 
 4669.00                  MOVE ZNGCCLN-PARAMS   TO SYSR-PARAMS                            160407 
 4670.00                  PERFORM 600-FATAL-ERROR                                         160407 
 4671.00            END-EVALUATE.                                                         160407 
 4672.00       *                                                                          160407 
 4673.00        N490-EXIT.                                                                160407 
 4674.00             EXIT.                                                                160407 
 4675.00       /                                                                          160407 
 4676.00        X100-ZPTREFC-IO SECTION.                                                  160916 
 4677.00       ************************                                                   160916 
 4678.00        X110-START.                                                               160916 
 4679.00                                                                                  160916 
 4680.00            MOVE O-K                    TO ZPTREFC-STATUZ                         160916 
 4681.00            CALL 'ZPTREFCIO'         USING ZPTREFC-PARAMS                         160916 
 4682.00       *                                                                          160916 
 4683.00            IF  ZPTREFC-STATUZ       NOT = O-K                                    160916 
 4684.00            AND ZPTREFC-STATUZ       NOT = ENDP                                   160916 
 4685.00                MOVE ZPTREFC-PARAMS     TO SYSR-PARAMS                            160916 
 4686.00                MOVE ZPTREFC-STATUZ     TO SYSR-STATUZ                            160916 
 4687.00                PERFORM 600-FATAL-ERROR                                           160916 
 4688.00            END-IF                                                                160916 
 4689.00            .                                                                     160916 
 4690.00        X190-EXIT.                                                                160916 
 4691.00             EXIT.                                                                160916 
 4692.00       /                                                                          160916 
 4693.00        X200-LIFEARC-IO SECTION.                                                  160916 
 4694.00       ************************                                                   160916 
 4695.00        X210-START.                                                               160916 
 4696.00                                                                                  160916 
 4697.00            MOVE O-K                    TO LIFEARC-STATUZ                         160916 
 4698.00            CALL 'LIFEARCIO'         USING LIFEARC-PARAMS                         160916 
 4699.00       *                                                                          160916 
 4700.00            IF  LIFEARC-STATUZ          NOT = O-K                                 160916 
 4701.00            AND LIFEARC-STATUZ          NOT = ENDP                                160916 
 4702.00                MOVE LIFEARC-PARAMS        TO SYSR-PARAMS                         160916 
 4703.00                MOVE LIFEARC-STATUZ        TO SYSR-STATUZ                         160916 
 4704.00                PERFORM 600-FATAL-ERROR                                           160916 
 4705.00            END-IF                                                                160916 
 4706.00            .                                                                     160916 
 4707.00        X290-EXIT.                                                                160916 
 4708.00             EXIT.                                                                160916 
 4709.00       /                                                                          160916 
 4710.00        X300-COVRENQ-IO SECTION.                                                  160916 
 4711.00       ************************                                                   160916 
 4712.00        X310-START.                                                               160916 
 4713.00                                                                                  160916 
 4714.00            MOVE O-K                    TO COVRENQ-STATUZ                         160916 
 4715.00            CALL 'COVRENQIO'         USING COVRENQ-PARAMS                         160916 
 4716.00       *                                                                          160916 
 4717.00            IF  COVRENQ-STATUZ       NOT = O-K                                    160916 
 4718.00            AND COVRENQ-STATUZ       NOT = ENDP                                   160916 
 4719.00                MOVE COVRENQ-PARAMS     TO SYSR-PARAMS                            160916 
 4720.00                MOVE COVRENQ-STATUZ     TO SYSR-STATUZ                            160916 
 4721.00                PERFORM 600-FATAL-ERROR                                           160916 
 4722.00            END-IF                                                                160916 
 4723.00            .                                                                     160916 
 4724.00        X390-EXIT.                                                                160916 
 4725.00             EXIT.                                                                160916 
 4726.00                                                                         <ATHC60> 180601 
 4727.00        X600-CALL-DATCON2 SECTION.                                       <ATHC60> 180601 
 4728.00       ****************************                                      <ATHC60> 180601 
 4729.00        X600-START.                                                      <ATHC60> 180601 
 4730.00                                                                         <ATHC60> 180601 
 4731.00            INITIALIZE DTC2-DATCON2-REC                                  <ATHC60> 180601 
 4732.00            INITIALIZE DTC2-INT-DATE-1                                   <ATHC60> 180601 
 4733.00            INITIALIZE DTC2-INT-DATE-2                                   <ATHC60> 180601 
 4734.00                                                                         <ATHC60> 180601 
 4735.00            MOVE WSAA-DATCON2-FROM-DATE TO DTC2-INT-DATE-1               <ATHC60> 180601 
 4736.00            MOVE WSAA-DATCON2-FOR       TO DTC2-FREQ-FACTOR              <ATHC60> 180601 
 4737.00            MOVE WSAA-DATCON2-FREQ      TO DTC2-FREQUENCY                <ATHC60> 180601 
 4738.00                                                                         <ATHC60> 180601 
 4739.00            PERFORM X650-CALL-DATCON2-IO                                 <ATHC60> 180601 
 4740.00                                                                         <ATHC60> 180601 
 4741.00            MOVE DTC2-INT-DATE-2        TO WSAA-DATCON2-DATE             <ATHC60> 180601 
 4742.00            .                                                            <ATHC60> 180601 
 4743.00        X600-EXIT.                                                       <ATHC60> 180601 
 4744.00            EXIT.                                                        <ATHC60> 180601 
 4745.00       /                                                                 <ATHC60> 180601 
 4746.00        X650-CALL-DATCON2-IO SECTION.                                    <ATHC60> 180601 
 4747.00       *******************************                                   <ATHC60> 180601 
 4748.00        X650-START.                                                      <ATHC60> 180601 
 4749.00                                                                         <ATHC60> 180601 
 4750.00            CALL 'DATCON2'           USING DTC2-DATCON2-REC              <ATHC60> 180601 
 4751.00                                                                         <ATHC60> 180601 
 4752.00            IF  DTC2-STATUZ          NOT = O-K                           <ATHC60> 180601 
 4753.00                MOVE DTC2-DATCON2-REC   TO SYSR-PARAMS                   <ATHC60> 180601 
 4754.00                MOVE DTC2-STATUZ        TO SYSR-STATUZ                   <ATHC60> 180601 
 4755.00                PERFORM 600-FATAL-ERROR                                  <ATHC60> 180601 
 4756.00            END-IF                                                       <ATHC60> 180601 
 4757.00            .                                                            <ATHC60> 180601 
 4758.00        X650-EXIT.                                                       <ATHC60> 180601 
 4759.00            EXIT.                                                        <ATHC60> 180601 
