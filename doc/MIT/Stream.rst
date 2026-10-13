.. _MIT/Stream:

Stream Model Independent Transactions
#####################################

.. _MIT/Stream/Overview:

Overview
********

The Stream Model Independent Transaction package (:file:`StreamTransactionPkg.vhd`) defines a transaction interface (a
record for communication between the test sequencer and the verification component) and transaction initiation
procedures that are suitable for Stream Interfaces.

Be sure to read the OSVVM's Structured Testbench Framework Guide first. This guide provides background on the overall
structure of OSVVM's testbench and how the pieces of the Model Independent Transactions fit within the overall approach.

All verification components (VCs) that use this interface, support a common set of transactions (or API). Hence, a test
writer who understands the transactions for one verification component will also understand the transactions of another
verification component that also uses the same package. This makes the job of a verification engineer easier.

From a test writers point of view, the main difference between different verification components that support this
package is the configuration of verification component interface specific features - such as error injection for a UART
or configuration of TID, TDest, TUser, and TLast for AxiStream.

Having a shared set of transactions improves test case reuse between different verification components – a case where
reuse is rarely possible with other verification methodologies.

.. _MIT/Stream/TransmittersAndReceivers:

Transmitters and Receivers
**************************

A Transmitter is the agent that sends information on a stream interface, and a Receiver is the agent that receives
information on a stream interface. Terminology may vary from interface to interface, however, the use of transmitter and
receiver for any given streaming interface is unambiguous.

.. _MIT/Stream/StreamTransactionInterface:

Stream Transaction Interface
****************************

The stream transaction interface connects the test sequencer to a verification component. As such, it is the primary
channel for information exchange between the two. This is done with the record type :vhdlcode:`StreamRecType`.

.. _MIT/Stream/StreamRecType:

StreamRecType
=============

.. code-block:: VHDL

   type StreamRecType is record
     -- Handshaking controls
     --   Used by RequestTransaction in the Transaction Procedures
     --   Used by WaitForTransaction in the Verification Component
     --   RequestTransaction and WaitForTransaction are in osvvm.TbUtilPkg
     Rdy             : RdyType ;
     Ack             : AckType ;
     -- Transaction Type
     Operation       : StreamOperationType ;
     -- Data and Transaction Parameter to and from verification component
     DataToModel     : std_logic_vector_max_c ;
     ParamToModel    : std_logic_vector_max_c ;
     DataFromModel   : std_logic_vector_max_c ;
     ParamFromModel  : std_logic_vector_max_c ;
     -- BurstFifo
     BurstFifo       : ScoreboardIdType ;
     -- Verification Component Options Parameters - used by SetModelOptions
     IntToModel      : integer_max ;
     IntFromModel    : integer_max ;
     BoolToModel     : boolean_max ;
     BoolFromModel   : boolean_max ;
     TimeToModel     : time_max ;
     TimeFromModel   : time_max ;
     -- Verification Component Options Type
     Options         : integer_max ;
   end record StreamRecType ;

One of the challenges of using a single record, such as :vhdlcode:`StreamRecType`, as an interface is dealing with
multiple drivers on each record element. OSVVM does this giving each element a resolved type, such as
:vhdlcode:`bit_max`, :vhdlcode:`std_logic_vector_max_c`, :vhdlcode:`integer_max`, :vhdlcode:`time_max`, and
:vhdlcode:`boolean_max`. These are defined in the OSVVM package :vhdlcode:`ResolutionPkg`. These types allow the record
to support multiple drivers and use resolution functions based on function maximum (return largest value).

The type :vhdlcode:`StreamOperationType` is discussed in VC section of this document.

.. _MIT/Stream/BurstFifoIsInTheInterface:

BurstFifo is in the Interface
=============================

The :vhdlcode:`BurstFifo` is inside :vhdlcode:`StreamRecType`. This means it is easily accessible to both the
verification component and the Test Sequencer (:vhdlcode:`TestCtrl`). The type, :vhdlcode:`ScoreboardIdType`, is a
reference (though not an access type) to the scoreboard singleton data structure in :vhdlcode:`ScoreboardGenericPkg`.
Using :vhdlcode:`ScoreboardIdType` allows the structure to be used as either a FIFO (by :vhdlcode:`SendBurst` or
:vhdlcode:`GetBurst`) or a Scoreboard (by :vhdlcode:`CheckBurst`). The FIFO is :vhdlcode:`std_logic_vector` based and
uses the :vhdlcode:`ScoreboardPkg_slv` instance from :file:`OsvvmLibraries/osvvm`.

.. _MIT/Stream/UsageOfTheTransactionInterfaceStreamRecType:

Usage of the Transaction Interface (StreamRecType)
==================================================

The data and parameter fields of the :vhdlcode:`StreamRecType` are unconstrained. Unconstrained objects may be used on
component/entity interfaces. The record fields need to be sized by the record signal that is mapped as the actual in the
test harness of the testbench. :ref:`Figure 1 <MIT/Stream/Figure1>` shows the declaration :vhdlcode:`StreamTxRec` (which
connects the :vhdlcode:`AxiStreamTransmitter` to :vhdlcode:`TestCtrl`) and :vhdlcode:`StreamRxRec` (which connects the
:vhdlcode:`AxiStreamReceiver` to :vhdlcode:`TestCtrl`).

.. code-block:: VHDL
   :caption: Figure 1. StreamRecType
   :name: MIT/Stream/Figure1

   constant AXI_PARAM_WIDTH : integer :=
         TID'length + TDest'length + TUser'length + 1;

   signal StreamTxRec, StreamRxRec : StreamRecType(
       DataToModel   (AXI_DATA_WIDTH-1  downto 0),
       ParamToModel  (AXI_PARAM_WIDTH-1 downto 0),
       DataFromModel (AXI_DATA_WIDTH-1  downto 0),
       ParamFromModel(AXI_PARAM_WIDTH-1 downto 0)
     ) ;

.. _MIT/Stream/RunningTheStreamDemo:

Running the Stream Demo
***********************

The best way to learn is by trying things out as you go. In this step you will download OSVVM, build the libraries, and
then run the demo. Code from the demo is shown in examples in the respective sections.

OSVVM is available on GitHub at https://github.com/OSVVM as a git repository or at https://osvvm.org/downloads as a ZIP
file. Retrieve OSVVM from GitHub using git as shown in :ref:`Figure 2 <MIT/Stream/Figure2>`. Note that the "—recursive"
option is required since the OSVVM repositories are submodules of OsvvmLibraries. Submodules greatly simplify
development and deployment of the libraries.

.. code-block:: shell
   :caption: Figure 2. Retrieving OSVVM from GitHub
   :name: MIT/Stream/Figure2

   git clone --recursive https://github.com/OSVVM/OsvvmLibraries.git

Prior to starting the OSVVM scripting environment, create a directory named sim in which to run your simulations. Start
your simulator and go to the sim directory. Once there, use the steps in :ref:`Figure 3 <MIT/Stream/Figure3>` to build
the OSVVM Libraries (utility and verification component). These directions are supported in Mentor QuestaSim/ModelSim or
Aldec RivieraPRO. Aldec's ActiveHDL, Synopsys' VCS, and Cadence's Xcelium are also supported but require a few extra
steps. For these steps and additional details of the OSVVM scripting environment see
:osvvmdoc:`Script_user_guide.pdf <Script_user_guide>` (in :file:`OsvvmLibraries/Documentation`).

.. code-block:: tcl
   :caption: Figure 3. Building OSVVM and running the Demo
   :name: MIT/Stream/Figure3

   cd sim
   source ../OsvvmLibraries/Scripts/StartUp.tcl
   build  ../OsvvmLibraries
   build  ../OsvvmLibraries/AXI4/AxiStream/RunDemoTests.pro

The intent of the OSVVM scripting is to make compiling and running your simulations independent of the simulator you are
using.

GHDL can be run using tclsh. In windows, using MSYS2/MinGW64 start tclsh using "winpty tclsh".

.. _MIT/Stream/TypesOfTransactions:

Types of Transactions
*********************

A transaction may be either a directive or an interface transaction.

Directive transactions interact with the verification component without generating any transactions or interface
waveforms. Examples of these are :vhdlcode:`WaitForClock` and :vhdlcode:`GetAlertLogID`.

An interface transaction results in interface signaling to the DUT. An interface transaction may be either blocking
(such as :vhdlcode:`Send` or :vhdlcode:`Get`) or non-blocking (such as :vhdlcode:`SendAsync` and :vhdlcode:`TryGet`).

A blocking transaction is an interface transaction that does not does not return (complete) until the interface
operation requested by the transaction has completed.

An asynchronous transaction is nonblocking interface transaction that returns before the transaction has completed -
typically immediately and before the transaction has started. An asynchronous transaction has "Async" as part of its
name.

A Try transaction is nonblocking interface transaction that checks to see if transaction information is available, such
as read data, and if it is returns it. A Try transaction has "Try" as part of its name.

.. _MIT/Stream/BasicBlockingTransactions:

Basic Blocking Transactions
***************************

Basic blocking transactions dispatch a transaction to the verification component and wait for the verification component
to finish the operation on the DUT interface before returning. These represent the minimal set of transactions that a
verification component must implement.

In the discussion about blocking transactions, the examples for a particular set of transactions use example code from
this test.

.. _MIT/Stream/TransmitterSend:

Transmitter: Send
=================

Blocking :vhdlcode:`Send` Transaction. :vhdlcode:`Param`, when present, is an extra parameter used by the verification
component. The UART verification component uses :vhdlcode:`Param` for error injection.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure Send (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  Data            : in    std_logic_vector ;
     constant  Param           : in    std_logic_vector ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

   ------------------------------------------------------------
   procedure Send (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  Data            : in    std_logic_vector ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

.. _MIT/Stream/ReceiverGet:

Receiver: Get
=============

:vhdlcode:`Get` is a blocking get transaction. :vhdlcode:`Param`, when present, is an extra parameter used by the
verification component.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure Get (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     variable  Data            : out   std_logic_vector ;
     variable  Param           : out   std_logic_vector ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

   ------------------------------------------------------------
   procedure Get (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     variable  Data            : out   std_logic_vector ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

.. _MIT/Stream/BasicBlockingTransactions/Example:

Example
=======

The code below transmits of 32 words.

.. code-block:: VHDL

   AxiTransmitterProc : process
   begin
     . . .
     log("Transmit 32 words") ;
     for I in 1 to 32 loop
       Send( StreamTxRec, X"0000_0000" + I ) ;
     end loop ;

The code below receives and checks the 32 words.

.. code-block:: VHDL

   AxiReceiverProc: process
     variable RxData : std_logic_vector(31 downto 0);
   begin
     . . .
     for I in 1 to 32 loop
       Get(StreamRxRec, RxData) ;
       AffirmIfEqual(RxData, X"0000_0000" + I, "RxData") ;
     end loop ;

.. _MIT/Stream/CheckingForBasicBlockingTransactions:

Checking for Basic Blocking Transactions
****************************************

.. _MIT/Stream/ReceiverCheck:

Receiver: Check
===============

:vhdlcode:`Check` is a blocking check transaction. Data is the expected value to be received. :vhdlcode:`Param`, when
present, is an extra parameter used by the verification component. The UART verification component uses
:vhdlcode:`Param` for received error status.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure Check (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  Data            : in    std_logic_vector ;
     constant  Param           : in    std_logic_vector ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

   ------------------------------------------------------------
   procedure Check (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  Data            : in    std_logic_vector ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

.. _MIT/Stream/CheckingForBasicBlockingTransactions/Example:

Example
=======

The code below transmits of 32 words.

.. code-block:: VHDL

   AxiTransmitterProc : process
   begin
     . . .
     log("Transmit 32 words") ;
     for I in 1 to 32 loop
       Send( StreamTxRec, X"0000_1000" + I ) ;
     end loop ;

The code below checks the 32 words.

.. code-block:: VHDL

   AxiReceiverProc: process
   begin
     . . .
     for I in 1 to 32 loop
       Check(StreamRxRec, X"0000_1000" + I ) ;
     end loop ;

.. _MIT/Stream/BasicBlockingBurstTransactions:

Basic Blocking Burst Transactions
*********************************

.. _MIT/Stream/TransmitterSendBurst:

Transmitter: SendBurst
======================

:vhdlcode:`SendBurst` is a blocking send burst transaction. :vhdlcode:`Param`, when present, is an extra parameter used
by the verification component. The UART verification component uses :vhdlcode:`Param` for error injection.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure SendBurst (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  NumFifoWords    : In    integer ;
     constant  Param           : in    std_logic_vector ;
     constant  StatusMsgOn     : in    boolean := FALSE   ) ;

   ------------------------------------------------------------
   procedure SendBurst (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  NumFifoWords    : In    integer ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

.. _MIT/Stream/ReceiverGetBurst:

Receiver: GetBurst
==================

:vhdlcode:`GetBurst` is a blocking get burst transaction. :vhdlcode:`Param`, when present, is an extra parameter used by
the verification component. The UART verification component uses :vhdlcode:`Param` for checking error injection.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure GetBurst (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     variable  NumFifoWords    : inout integer ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

   ------------------------------------------------------------
   procedure GetBurst (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     variable  NumFifoWords    : inout integer ;
     variable  Param           : out   std_logic_vector ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

.. _MIT/Stream/BasicBlockingBurstTransactions/Example:

Example
=======

The code below transmits 32 words as a burst.

.. code-block:: VHDL

   AxiTransmitterProc : process
   begin
     . . .
     log("Send 32 word burst") ;
     for I in 1 to 32 loop
       Push( StreamTxRec.BurstFifo, X"0000_2000" + I  ) ;
     end loop ;
     SendBurst(StreamTxRec, 32) ;

The code below receives and checks the 32 word burst.

.. code-block:: VHDL

   AxiReceiverProc: process
     variable RxData : std_logic_vector(31 downto 0);
   begin
     . . .
     GetBurst(StreamRxRec, NumBytes) ;
     AffirmIfEqual(NumBytes, 32, "Receiver: 32 Received") ;
     for I in 1 to 32 loop
       RxData := Pop( StreamRxRec.BurstFifo ) ;
       AffirmIfEqual(RxData, X"0000_2000" + I , "RxData") ;
     end loop ;

.. _MIT/Stream/CheckingForBlockingBurstTransactions:

Checking for Blocking Burst Transactions
****************************************

.. _MIT/Stream/ReceiverCheckBurst:

Receiver: CheckBurst
====================

:vhdlcode:`CheckBurst` is a blocking check burst transaction. :vhdlcode:`Param`, when present, is an extra parameter
used by the verification component. The UART verification component uses :vhdlcode:`Param` for checking error injection.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure CheckBurst (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  NumFifoWords    : In    integer ;
     constant  Param           : in    std_logic_vector ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

   ------------------------------------------------------------
   procedure CheckBurst (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  NumFifoWords    : In    integer ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

.. _MIT/Stream/CheckingForBlockingBurstTransactions/Example:

Example
=======

The code below transmits 32 words as a burst.

.. code-block:: VHDL

   AxiTransmitterProc : process
   begin
     . . .
     log("Send 32 word burst") ;
     for I in 1 to 32 loop
       Push( StreamTxRec.BurstFifo, X"0000_3000" + I ) ;
     end loop ;
     SendBurst(StreamTxRec, 32) ;

The code below checks the 32 word burst.

.. code-block:: VHDL

   AxiReceiverProc: process
     variable RxData : std_logic_vector(31 downto 0);
   begin
     . . .
     for I in 1 to 32 loop
       Push( StreamRxRec.BurstFifo, X"0000_3000" + I  ) ;
     end loop ;
     CheckBurst(StreamRxRec, 32) ;

.. _MIT/Stream/PatternsForBlockingBurstTransactions:

Patterns for Blocking Burst Transactions
****************************************

.. _MIT/Stream/PatternsForBlockingBurstTransactions/BurstWithAVectorOfWords:

Burst with a Vector of Words
============================

.. _MIT/Stream/TransmitterSendBurstVector:

Transmitter: SendBurstVector
----------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure SendBurstVector (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant VectorOfWords  : In    slv_vector ;
     constant Param          : In    std_logic_vector ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

   ------------------------------------------------------------
   procedure SendBurstVector (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant VectorOfWords  : In    slv_vector ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/ReceiverCheckBurstVector:

Receiver: CheckBurstVector
--------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure CheckBurstVector (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant VectorOfWords  : In    slv_vector ;
     constant Param          : In    std_logic_vector ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

   ------------------------------------------------------------
   procedure CheckBurstVector (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant VectorOfWords  : In    slv_vector ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/BurstWithAVectorOfWords/Example:

Example
-------

The code below transmits 13 words as a burst.

.. code-block:: VHDL

   AxiTransmitterProc : process
   begin
     . . .
     log("SendBurstVector 13 word burst") ;
     SendBurstVector(StreamTxRec,
         (X"0000_4001", X"0000_4003", X"0000_4005", X"0000_4007", X"0000_4009",
          X"0000_4011", X"0000_4013", X"0000_4015", X"0000_4017", X"0000_4019",
          X"0000_4021", X"0000_4023", X"0000_4025") ) ;

The code below checks the 13 words.

.. code-block:: VHDL

   AxiReceiverProc: process
     variable RxData : std_logic_vector(31 downto 0);
   begin
     . . .
     CheckBurstVector(StreamRxRec,
         (X"0000_4001", X"0000_4003", X"0000_4005", X"0000_4007", X"0000_4009",
          X"0000_4011", X"0000_4013", X"0000_4015", X"0000_4017", X"0000_4019",
          X"0000_4021", X"0000_4023", X"0000_4025") ) ;

.. _MIT/Stream/PatternsForBlockingBurstTransactions/BurstWithAnIncrementingPattern:

Burst with an Incrementing Pattern
==================================

.. _MIT/Stream/TransmitterSendBurstIncrement:

Transmitter: SendBurstIncrement
-------------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure SendBurstIncrement (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     constant Param          : In    std_logic_vector ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

   ------------------------------------------------------------
   procedure SendBurstIncrement (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/ReceiverCheckBurstIncrement:

Receiver: CheckBurstIncrement
-----------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure CheckBurstIncrement (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     constant Param          : In    std_logic_vector ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

   ------------------------------------------------------------
   procedure CheckBurstIncrement (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/BurstWithAnIncrementingPattern/Example:

Example
-------

The code below transmits of 16 words.

.. code-block:: VHDL

   AxiTransmitterProc : process
   begin
     . . .
     log("SendBurstIncrement 16 word burst") ;
     SendBurstIncrement(StreamTxRec, X"0000_5000", 16) ;

The code below checks the 16 words.

.. code-block:: VHDL

   AxiReceiverProc: process
     variable RxData : std_logic_vector(31 downto 0);
   begin
     . . .
     CheckBurstIncrement(StreamRxRec, X"0000_5000", 16) ;

.. _MIT/Stream/PatternsForBlockingBurstTransactions/BurstWithARandomPattern:

Burst with a Random Pattern
===========================

.. _MIT/Stream/BurstWithARandomPattern/TransmitterSendBurstRandom:

Transmitter: SendBurstRandom
----------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure SendBurstRandom (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     constant Param          : In    std_logic_vector ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

   ------------------------------------------------------------
   procedure SendBurstRandom (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/BurstWithARandomPattern/ReceiverCheckBurstRandom:

Receiver: CheckBurstRandom
--------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure CheckBurstRandom (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     constant Param          : In    std_logic_vector ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

   ------------------------------------------------------------
   procedure CheckBurstRandom (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/BurstWithARandomPattern/Example:

Example
-------

The code below transmits of 16 words.

.. code-block:: VHDL

   AxiTransmitterProc : process
   begin
     . . .
     log("SendBurstRandom 24 word burst") ;
     SendBurstRandom(StreamTxRec, X"0000_6000", 24) ;

The code below checks the 16 words.

.. code-block:: VHDL

   AxiReceiverProc: process
     variable RxData : std_logic_vector(31 downto 0);
   begin
     . . .
     CheckBurstRandom(StreamRxRec, X"0000_6000", 24) ;

.. _MIT/Stream/PatternsForBlockingBurstTransactions/BurstWithAnIntelligentCoverageRandomPattern:

Burst with an Intelligent Coverage Random Pattern
=================================================

.. _MIT/Stream/BurstWithAnIntelligentCoverageRandomPattern/TransmitterSendBurstRandom:

Transmitter: SendBurstRandom
----------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure SendBurstRandom (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant CoverID        : In    CoverageIDType ;
     constant NumFifoWords   : In    integer ;
     constant FifoWidth      : In    integer ;
     constant Param          : In    std_logic_vector ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

   ------------------------------------------------------------
   procedure SendBurstRandom (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant CoverID        : In    CoverageIDType ;
     constant NumFifoWords   : In    integer ;
     constant FifoWidth      : In    integer ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/BurstWithAnIntelligentCoverageRandomPattern/ReceiverCheckBurstRandom:

Receiver: CheckBurstRandom
--------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure CheckBurstRandom (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant CoverID        : In    CoverageIDType ;
     constant NumFifoWords   : In    integer ;
     constant FifoWidth      : In    integer ;
     constant Param          : In    std_logic_vector ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

   ------------------------------------------------------------
   procedure CheckBurstRandom (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant CoverID        : In    CoverageIDType ;
     constant NumFifoWords   : In    integer ;
     constant FifoWidth      : In    integer ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/BurstWithAnIntelligentCoverageRandomPattern/Example:

Example
-------

The code below transmits of 16 words.

.. code-block:: VHDL

   AxiTransmitterProc : process
     variable CoverID : CoverageIdType ;
   begin
     . . .
     log("SendBurstRandom 42 word burst") ;
     SendBurstRandom(StreamTxRec, CoverID, 42, 32) ;

The code below checks the 16 words.

.. code-block:: VHDL

   AxiReceiverProc: process
     variable CoverID : CoverageIdType ;
   begin
     . . .
     CheckBurstRandom (StreamRxRec, CoverID, 42, 32) ;

.. _MIT/Stream/FIFOFillAndCheckPatternsAndCompositeBursts:

FIFO Fill and Check Patterns and Composite Bursts
*************************************************

FIFO fill patterns can be used in conjunction with :vhdlcode:`SendBurst` and :vhdlcode:`CheckBurst` to build burst
transactions that are a composite of Vector, Increment, and Random patterns. Likewise FIFO check patterns can be used
with :vhdlcode:`GetBurst` in a similar fashion.

FIFO fill and check patterns are implemented in :file:`FifoFillPkg_slv.vhd` (in the :vhdlcode:`osvvm_common` library).

.. _MIT/Stream/FIFOFillPatterns:

FIFO Fill Patterns
==================

.. _MIT/Stream/FillWithAVectorOfWords:

Fill with a Vector of Words
---------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure PushBurstVector (
   -- Push each value in the VectorOfWords parameter into the FIFO.
   -- FifoWidth must match the std_logic_vector parameter.
   ------------------------------------------------------------
     constant Fifo          : In    ScoreboardIdType ;
     constant VectorOfWords : In    slv_vector
   ) ;
   ------------------------------------------------------------
   procedure PushBurstVector (
   -- Push each value in the VectorOfWords parameter into the FIFO.
   -- Only FifoWidth bits of each value will be pushed.
   ------------------------------------------------------------
     constant Fifo           : in    ScoreboardIdType ;
     constant VectorOfWords  : in    integer_vector ;
     constant FifoWidth      : in    integer
   ) ;

.. _MIT/Stream/FillWithAnIncrementingPattern:

Fill with an Incrementing Pattern
---------------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure PushBurstIncrement (
   -- Push Count number of values into FIFO.  The first value
   -- pushed will be FirstWord and following values are one greater
   -- than the previous one.
   -- FifoWidth must match the std_logic_vector parameter.
   ------------------------------------------------------------
     constant Fifo           : In    ScoreboardIdType ;
     constant FirstWord      : In    std_logic_vector ;
     constant Count          : In    integer
   ) ;
   ------------------------------------------------------------
   procedure PushBurstIncrement (
   -- Push Count number of values into FIFO.  The first value
   -- pushed will be FirstWord and following values are one greater
   -- than the previous one.
   -- Only FifoWidth bits of each value will be pushed.
   ------------------------------------------------------------
     constant Fifo         : in    ScoreboardIdType ;
     constant FirstWord    : in    integer ;
     constant Count        : in    integer ;
     constant FifoWidth    : in    integer := 8
   ) ;

.. _MIT/Stream/FillWithARandomPattern:

Fill with a Random Pattern
--------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure PushBurstRandom (
   -- Push Count number of values into FIFO.  The first value
   -- pushed will be FirstWord and following values are randomly generated
   -- using the first value as the randomization seed.
   -- FifoWidth must match the std_logic_vector parameter.
   ------------------------------------------------------------
     constant Fifo           : In    ScoreboardIdType ;
     constant FirstWord      : In    std_logic_vector ;
     constant Count          : In    integer
   ) ;
   ------------------------------------------------------------
   procedure PushBurstRandom (
   -- Push Count number of values into FIFO.  The first value
   -- pushed will be FirstWord and following values are randomly generated
   -- using the first value as the randomization seed.
   -- Only FifoWidth bits of each value will be pushed.
   ------------------------------------------------------------
     constant Fifo         : in    ScoreboardIdType ;
     constant FirstWord    : in    integer ;
     constant Count        : in    integer ;
     constant FifoWidth    : in    integer := 8
   ) ;

.. _MIT/Stream/FillWithAnIntelligentCoverageRandomPattern:

Fill with an Intelligent Coverage Random Pattern
------------------------------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   -- Experimental and Provisional
   procedure PushBurstRandom (
   -- Push Count number of values into FIFO.  Values are
   -- randomly generated using the coverage model.
   -- Only FifoWidth bits of each value will be pushed.
   ------------------------------------------------------------
     constant Fifo         : in    ScoreboardIdType ;
     constant CoverID      : in    CoverageIdType ;
     constant Count        : in    integer ;
     constant FifoWidth    : in    integer := 8
   ) ;

.. _MIT/Stream/FIFOFillPatterns/ExampleCombiningPatterns:

Example: Combining Patterns
---------------------------

The code below transmits of 42 words.

.. code-block:: VHDL

   log("Combining Patterns:  Vector, Increment, Random, Intelligent Coverage") ;
   PushBurstVector(StreamTxRec.BurstFifo,
       (X"0000_A001", X"0000_A003", X"0000_A005", X"0000_A007", X"0000_A009",
        X"0000_A011", X"0000_A013", X"0000_A015", X"0000_A017", X"0000_A019") ) ;
   PushBurstIncrement(StreamTxRec.BurstFifo, X"0000_A100", 10) ;
   PushBurstRandom   (StreamTxRec.BurstFifo, X"0000_A200", 6) ;
   CoverID := NewID("Cov1a") ;
   InitSeed(CoverID, 5) ; -- Get a common seed in both processes
   AddBins(CoverID, 1,
       GenBin(16#A000#, 16#A007#) & GenBin(16#A010#, 16#A017#) &
       GenBin(16#A020#, 16#A027#) & GenBin(16#A030#, 16#A037#)) ;
   PushBurstRandom(StreamTxRec.BurstFifo, CoverID, 16, 32) ;
   SendBurst(StreamTxRec, 42) ;

The code below checks the 42 words.

.. code-block:: VHDL

   PushBurstVector(StreamRxRec.BurstFifo,
       (X"0000_A001", X"0000_A003", X"0000_A005", X"0000_A007", X"0000_A009",
        X"0000_A011", X"0000_A013", X"0000_A015", X"0000_A017", X"0000_A019") ) ;
   PushBurstIncrement(StreamRxRec.BurstFifo, X"0000_A100", 10) ;
   PushBurstRandom(StreamRxRec.BurstFifo, X"0000_A200", 6) ;
   CoverID := NewID("Cov2a") ;
   InitSeed(CoverID, 5) ; -- Get a common seed in both processes
   AddBins(CoverID, 1,
       GenBin(16#A000#, 16#A007#) & GenBin(16#A010#, 16#A017#) &
       GenBin(16#A020#, 16#A027#) & GenBin(16#A030#, 16#A037#)) ;
   PushBurstRandom(StreamRxRec.BurstFifo, CoverID, 16, 32) ;
   CheckBurst(StreamRxRec, 42) ;

.. _MIT/Stream/FIFOCheckPatterns:

FIFO Check Patterns
===================

.. _MIT/Stream/CheckWithAVectorOfWords:

Check with a Vector of Words
----------------------------

.. code-block:: VHDL

     ------------------------------------------------------------
   procedure CheckBurstVector (
   -- Check values from the FIFO against the values
   -- in the VectorOfWords parameter.
   -- Width of VectorOfWords(i) shall match the width of the Fifo
   ------------------------------------------------------------
     constant Fifo           : in    ScoreboardIdType ;
     constant VectorOfWords  : in    slv_vector
   ) ;

   ------------------------------------------------------------
   procedure CheckBurstVector (
   -- Check values from the FIFO against the values
   -- in the VectorOfWords parameter.
   -- Each value of VectorOfWords shall be converted to FifoWidth bits wide.
   ------------------------------------------------------------
     constant Fifo           : in    ScoreboardIdType ;
     constant VectorOfWords  : in    integer_vector ;
     constant FifoWidth      : in    integer
   ) ;

.. _MIT/Stream/CheckWithAnIncrementingPattern:

Check with an Incrementing Pattern
----------------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure CheckBurstIncrement (
   -- Check values from the FIFO against the incrementing values
   -- that start with the value of the FirstWord.
   -- Width of FirstWord shall match the width of the Fifo
   ------------------------------------------------------------
     constant Fifo         : in    ScoreboardIdType ;
     constant FirstWord    : in    std_logic_vector ;
     constant Count        : in    integer
   ) ;

   ------------------------------------------------------------
   procedure CheckBurstIncrement (
   -- Check values from the FIFO against the incrementing values
   -- that start with the value of the FirstWord.
   -- Each value of VectorOfWords shall be converted to FifoWidth bits wide.
   ------------------------------------------------------------
     constant Fifo         : in    ScoreboardIdType ;
     constant FirstWord    : in    integer ;
     constant Count        : in    integer ;
     constant FifoWidth    : in    integer := 8
   ) ;

.. _MIT/Stream/CheckWithARandomPattern:

Check with a Random Pattern
---------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure CheckBurstRandom (
   -- Check values from the FIFO against the random values
   -- that are generated using the value of the FirstWord and
   -- NumFifoWords as the randomization seeds.
   -- Width of FirstWord shall match the width of the Fifo
   ------------------------------------------------------------
     constant Fifo         : in    ScoreboardIdType ;
     constant FirstWord    : in    std_logic_vector ;
     constant Count        : in    integer
   ) ;

   ------------------------------------------------------------
   procedure CheckBurstRandom (
   -- Check values from the FIFO against the random values
   -- that are generated using the value of the FirstWord and
   -- Count as the randomization seeds.
   -- Each value of VectorOfWords shall be converted to FifoWidth bits wide.
   ------------------------------------------------------------
     constant Fifo         : in    ScoreboardIdType ;
     constant FirstWord    : in    integer ;
     constant Count        : in    integer ;
     constant FifoWidth    : in    integer := 8
   ) ;

.. _MIT/Stream/CheckWithAnIntelligentCoverageRandomPattern:

Check with an Intelligent Coverage Random Pattern
-------------------------------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   -- Experimental and Provisional
   procedure CheckBurstRandom (
   ------------------------------------------------------------
     constant Fifo         : in    ScoreboardIdType ;
     constant CoverID      : in    CoverageIdType ;
     constant Count        : in    integer ;
     constant FifoWidth    : in    integer := 8
   ) ;

.. _MIT/Stream/FIFOCheckPatterns/ExampleCombiningPatterns:

Example: Combining Patterns
---------------------------

The code below transmits of 42 words.

.. code-block:: VHDL

   log("Combining Patterns:  Vector, Increment, Random, Intelligent Coverage") ;
   PushBurstVector(StreamTxRec.BurstFifo,
       (X"0000_A001", X"0000_A003", X"0000_A005", X"0000_A007", X"0000_A009",
        X"0000_A011", X"0000_A013", X"0000_A015", X"0000_A017", X"0000_A019") ) ;
   PushBurstIncrement(StreamTxRec.BurstFifo, X"0000_A100", 10) ;
   PushBurstRandom   (StreamTxRec.BurstFifo, X"0000_A200", 6) ;
   CoverID := NewID("Cov1a") ;
   InitSeed(CoverID, 5) ; -- Get a common seed in both processes
   AddBins(CoverID, 1,
       GenBin(16#A000#, 16#A007#) & GenBin(16#A010#, 16#A017#) &
       GenBin(16#A020#, 16#A027#) & GenBin(16#A030#, 16#A037#)) ;
   PushBurstRandom(StreamTxRec.BurstFifo, CoverID, 16, 32) ;
   SendBurst(StreamTxRec, 42) ;

The code below checks the 42 words.

.. code-block:: VHDL

   PushBurstVector(StreamRxRec.BurstFifo,
       (X"0000_A001", X"0000_A003", X"0000_A005", X"0000_A007", X"0000_A009",
        X"0000_A011", X"0000_A013", X"0000_A015", X"0000_A017", X"0000_A019") ) ;
   PushBurstIncrement(StreamRxRec.BurstFifo, X"0000_A100", 10) ;
   PushBurstRandom(StreamRxRec.BurstFifo, X"0000_A200", 6) ;
   CoverID := NewID("Cov2a") ;
   InitSeed(CoverID, 5) ; -- Get a common seed in both processes
   AddBins(CoverID, 1,
       GenBin(16#A000#, 16#A007#) & GenBin(16#A010#, 16#A017#) &
       GenBin(16#A020#, 16#A027#) & GenBin(16#A030#, 16#A037#)) ;
   PushBurstRandom(StreamRxRec.BurstFifo, CoverID, 16, 32) ;
   CheckBurst(StreamRxRec, 42) ;

.. _MIT/Stream/FIFOPopBurst:

FIFO Pop Burst
==============

.. _MIT/Stream/PopBurstVector:

PopBurstVector
--------------

:vhdlcode:`PopBurstVector` returns the contents of the FIFO as a vector. The vector can either be an array of
:vhdlcode:`std_logic_vector` (:vhdlcode:`slv_vector`) or :vhdlcode:`integer_vector`.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure PopBurstVector (
   -- Pop values from the FIFO into the VectorOfWords parameter.
   -- Width of VectorOfWords(i) shall match the width of the Fifo
   ------------------------------------------------------------
     constant Fifo           : in    ScoreboardIdType ;
     variable VectorOfWords  : out   slv_vector
   ) ;

   ------------------------------------------------------------
   procedure PopBurstVector (
   -- Pop values from the FIFO into the VectorOfWords parameter.
   -- Each value popped will be FifoWidth bits wide.
   ------------------------------------------------------------
     constant Fifo           : in    ScoreboardIdType ;
     variable VectorOfWords  : out   integer_vector
   ) ;

.. _MIT/Stream/ExamplePopBurstVector:

Example: PopBurstVector
-----------------------

The code below transmits of 42 words.

.. code-block:: VHDL

   log("SendBurstVector 5 word burst") ;
   SendBurstVector(StreamTxRec,
       (X"0000_C001", X"0000_C003", X"0000_C005", X"0000_C007", X"0000_C009") ) ;

   log("SendBurstVector 5 word burst") ;
   PushBurstVector(StreamTxRec.BurstFifo,
       (16#D001#, 16#D003#, 16#D005#, 16#D007#, 16#D009#), 32 ) ;
   SendBurst(StreamTxRec, 5) ;

The code below checks the 42 words.

.. code-block:: VHDL

   GetBurst(StreamRxRec, NumBytes) ;
   PopBurstVector(StreamRxRec.BurstFifo, slvBurstVector) ;
   AffirmIf(slvBurstVector =
       (X"0000_C001", X"0000_C003", X"0000_C005", X"0000_C007", X"0000_C009"),
       "slvBurstVector = C001, C003, C005, C007, C009") ;

   GetBurst(StreamRxRec, NumBytes) ;
   PopBurstVector(StreamRxRec.BurstFifo, intBurstVector) ;
   AffirmIf(intBurstVector =
       (16#D001#, 16#D003#, 16#D005#, 16#D007#, 16#D009#),
       "slvBurstVector = D001, D003, D005, D007, D009") ;

.. _MIT/Stream/BasicNonblockingTransactions:

Basic Nonblocking Transactions
******************************

Nonblocking transactions are either asynchronous transactions or try transactions. Asynchronous transactions return
before the transaction has been completed. Try transactions check to see if data is available and return it if it is. If
data is available, the :vhdlcode:`Available` parameter is set to TRUE, otherwise, it is FALSE.

Nonblocking transactions are useful creating different time relationships needed for split transaction interfaces, such
as AXI4 Full where Write Address, Write Data, Write Response, Read Address, and Read Data are all independent of each
other. Nonblocking transactions are also needed when a test sequencer dispatches transactions from a single process.

If you are just getting started with Stream Model Independent Transactions, this section largely parallels the blocking
transactions, so it is recommended to skip ahead to Directive Transactions.

.. _MIT/Stream/TransmitterSendAsync:

Transmitter: SendAsync
======================

:vhdlcode:`SendAsync` is an asynchronous / non-blocking send transaction. :vhdlcode:`Param`, when present, is an extra
parameter used by the verification component. The UART verification component uses :vhdlcode:`Param` for error
injection.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure SendAsync (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  Data            : in    std_logic_vector ;
     constant  Param           : in    std_logic_vector ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

   ------------------------------------------------------------
   procedure SendAsync (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  Data            : in    std_logic_vector ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

.. _MIT/Stream/ReceiverTryGet:

Receiver: TryGet
================

:vhdlcode:`TryGet` is a non-blocking try get transaction. If Data is available, get it and return available TRUE,
otherwise Return :vhdlcode:`Available` FALSE. :vhdlcode:`Param`, when present, is an extra parameter used by the
verification component. The UART verification component uses :vhdlcode:`Param` for received error status.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure TryGet (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     variable  Data            : out   std_logic_vector ;
     variable  Available       : out   boolean ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

   ------------------------------------------------------------
   procedure TryGet (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     variable  Data            : out   std_logic_vector ;
     variable  Param           : out   std_logic_vector ;
     variable  Available       : out   boolean ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

.. _MIT/Stream/CheckingForBasicNonblockingTransactions:

Checking for Basic Nonblocking Transactions
*******************************************

.. _MIT/Stream/ReceiverTryCheck:

Receiver: TryCheck
==================

:vhdlcode:`TryCheck` is a non-blocking try check transaction If Data is available, check it and return available TRUE,
otherwise Return :vhdlcode:`Available` FALSE. :vhdlcode:`Param`, when present, is an extra parameter used by the
verification component. The UART verification component uses :vhdlcode:`Param` for received error status.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure TryCheck (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  Data            : in    std_logic_vector ;
     constant  Param           : in    std_logic_vector ;
     variable  Available       : out   boolean ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

   ------------------------------------------------------------
   procedure TryCheck (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  Data            : in    std_logic_vector ;
     variable  Available       : out   boolean ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

.. _MIT/Stream/NonblockingBurstTransactions:

Nonblocking Burst Transactions
******************************

.. _MIT/Stream/TransmitterSendBurstAsync:

Transmitter: SendBurstAsync
===========================

:vhdlcode:`SendBurstAsync` is an asynchronous / non-blocking send burst transaction. :vhdlcode:`Param`, when present, is
an extra parameter used by the verification component. The UART verification component uses :vhdlcode:`Param` for error
injection.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure SendBurstAsync (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  NumFifoWords    : In    integer ;
     constant  Param           : in    std_logic_vector ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

   ------------------------------------------------------------
   procedure SendBurstAsync (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  NumFifoWords    : In    integer ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

.. _MIT/Stream/ReceiverTryGetBurst:

Receiver: TryGetBurst
=====================

:vhdlcode:`TryGetBurst` is a non-blocking try get burst transaction. If Data is available, get it and return available
TRUE, otherwise Return :vhdlcode:`Available` FALSE. :vhdlcode:`Param`, when present, is an extra parameter used by the
verification component. The UART verification component uses :vhdlcode:`Param` for received error status.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure TryGetBurst (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     variable  NumFifoWords    : inout integer ;
     variable  Available       : out   boolean ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

   ------------------------------------------------------------
   procedure TryGetBurst (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     variable  NumFifoWords    : inout integer ;
     variable  Param           : out   std_logic_vector ;
     variable  Available       : out   boolean ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

.. _MIT/Stream/NonblockingCheckBurstTransactions:

Nonblocking Check Burst Transactions
************************************

.. _MIT/Stream/ReceiverTryCheckBurst:

Receiver: TryCheckBurst
=======================

:vhdlcode:`TryCheckBurst` is a non-blocking try check burst transaction. :vhdlcode:`Param`, when present, is an extra
parameter used by the verification component. If BURST Data is available, check it and return available TRUE, otherwise
Return :vhdlcode:`Available` FALSE. The UART verification component uses :vhdlcode:`Param` for checking error injection.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure TryCheckBurst (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  NumFifoWords    : In    integer ;
     constant  Param           : in    std_logic_vector ;
     variable  Available       : out   boolean ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

   ------------------------------------------------------------
   procedure TryCheckBurst (
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  NumFifoWords    : In    integer ;
     variable  Available       : out   boolean ;
     constant  StatusMsgOn     : in    boolean := FALSE
   ) ;

.. _MIT/Stream/PatternsForNonblockingBurstTransactions:

Patterns for Nonblocking Burst Transactions
*******************************************

.. _MIT/Stream/PatternsForNonblockingBurstTransactions/BurstWithAVectorOfWords:

Burst with a Vector of Words
============================

.. _MIT/Stream/TransmitterSendBurstVectorAsync:

Transmitter: SendBurstVectorAsync
---------------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure SendBurstVectorAsync (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant VectorOfWords  : In    slv_vector ;
     constant Param          : In    std_logic_vector ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

   ------------------------------------------------------------
   procedure SendBurstVectorAsync (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant VectorOfWords  : In    slv_vector ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/ReceiverTryCheckBurstVector:

Receiver: TryCheckBurstVector
-----------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure TryCheckBurstVector (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant VectorOfWords  : In    slv_vector ;
     constant Param          : In    std_logic_vector ;
     variable Available      : Out   boolean ;
     constant StatusMsgOn    : In    boolean := false
   )  ;

   ------------------------------------------------------------
   procedure TryCheckBurstVector (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant VectorOfWords  : In    slv_vector ;
     variable Available      : Out   boolean ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/PatternsForNonblockingBurstTransactions/BurstWithAnIncrementingPattern:

Burst with an Incrementing Pattern
==================================

.. _MIT/Stream/TransmitterSendBurstIncrementAsync:

Transmitter: SendBurstIncrementAsync
------------------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure SendBurstIncrementAsync (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     constant Param          : In    std_logic_vector ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

   ------------------------------------------------------------
   procedure SendBurstIncrementAsync (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/ReceiverTryCheckBurstIncrement:

Receiver: TryCheckBurstIncrement
--------------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure TryCheckBurstIncrement (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     constant Param          : In    std_logic_vector ;
     variable Available      : Out   boolean ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

   ------------------------------------------------------------
   procedure TryCheckBurstIncrement (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     variable Available      : Out   boolean ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/PatternsForNonblockingBurstTransactions/BurstWithARandomPattern:

Burst with a Random Pattern
===========================

.. _MIT/Stream/BurstWithARandomPattern/TransmitterSendBurstRandomAsync:

Transmitter: SendBurstRandomAsync
---------------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure SendBurstRandomAsync (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     constant Param          : In    std_logic_vector ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

   ------------------------------------------------------------
   procedure SendBurstRandomAsync (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/BurstWithARandomPattern/ReceiverTryCheckBurstRandom:

Receiver: TryCheckBurstRandom
-----------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure TryCheckBurstRandom (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     constant Param          : In    std_logic_vector ;
     variable Available      : Out   boolean ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

   ------------------------------------------------------------
   procedure TryCheckBurstRandom (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant FirstWord      : In    std_logic_vector ;
     constant NumFifoWords   : In    integer ;
     variable Available      : Out   boolean ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/PatternsForNonblockingBurstTransactions/BurstWithAnIntelligentCoverageRandomPattern:

Burst with an Intelligent Coverage Random Pattern
=================================================

.. _MIT/Stream/BurstWithAnIntelligentCoverageRandomPattern/TransmitterSendBurstRandomAsync:

Transmitter: SendBurstRandomAsync
---------------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure SendBurstRandomAsync (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant CoverID        : In    CoverageIDType ;
     constant NumFifoWords   : In    integer ;
     constant FifoWidth      : In    integer ;
     constant Param          : In    std_logic_vector ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

   ------------------------------------------------------------
   procedure SendBurstRandomAsync (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant CoverID        : In    CoverageIDType ;
     constant NumFifoWords   : In    integer ;
     constant FifoWidth      : In    integer ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/BurstWithAnIntelligentCoverageRandomPattern/ReceiverTryCheckBurstRandom:

Receiver: TryCheckBurstRandom
-----------------------------

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure TryCheckBurstRandom (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant CoverID        : In    CoverageIDType ;
     constant NumFifoWords   : In    integer ;
     constant FifoWidth      : In    integer ;
     constant Param          : In    std_logic_vector ;
     variable Available      : Out   boolean ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

   ------------------------------------------------------------
   procedure TryCheckBurstRandom (
   ------------------------------------------------------------
     signal   TransactionRec : InOut StreamRecType ;
     constant CoverID        : In    CoverageIDType ;
     constant NumFifoWords   : In    integer ;
     constant FifoWidth      : In    integer ;
     variable Available      : Out   boolean ;
     constant StatusMsgOn    : In    boolean := false
   ) ;

.. _MIT/Stream/ReceiverGotBurst:

Receiver: GotBurst
------------------

Can be used to check to see if the interface has a burst or not. Used by co-sim interface and internal to transaction
interface to check if a burst is available when handling :vhdlcode:`TryCheckBurstVector`,
:vhdlcode:`TryCheckBurstIncrement`, and :vhdlcode:`TryCheckBurstRandom`.

.. code-block:: VHDL

     ------------------------------------------------------------
     procedure GotBurst (
     ------------------------------------------------------------
       signal    TransactionRec   : inout StreamRecType ;
       constant  NumFifoWords     : in    integer ;
       variable  Available        : out   boolean
     ) is
     begin
       TransactionRec.Operation   <= GOT_BURST ;
       -- NumFifoWords not used in all implementations - needed when interface has no
   burst capability
       TransactionRec.IntToModel  <= NumFifoWords ;
       RequestTransaction(Rdy => TransactionRec.Rdy, Ack => TransactionRec.Ack) ;
       Available := TransactionRec.BoolFromModel ;
     end procedure GotBurst ;

.. _MIT/Stream/DirectiveTransactions:

Directive Transactions
**********************

Directive transactions interact with the verification component without generating any transactions or interface
waveforms. These transactions are supported by all verification components.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure WaitForTransaction (
   --  Wait until pending (transmit) or next (receive) transaction(s) complete
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType
   ) ;

   ------------------------------------------------------------
   procedure WaitForClock (
   -- Wait for NumberOfClocks number of clocks
   -- relative to the verification component clock
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     constant  WaitCycles      : in    natural := 1
   ) ;

   ------------------------------------------------------------
   procedure GetTransactionCount (
   -- Get the number of transactions handled by the model.
   ------------------------------------------------------------
     signal    TransactionRec   : inout StreamRecType ;
     variable  TransactionCount : out   integer
   ) ;

   ------------------------------------------------------------
   procedure GetAlertLogID (
   -- Get the AlertLogID from the verification component.
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     variable  AlertLogID      : out   AlertLogIDType
   ) ;

   ------------------------------------------------------------
   procedure GetErrorCount (
   -- Error reporting for testbenches that do not use OSVVM AlertLogPkg
   -- Returns error count.  If an error count /= 0, also print errors
   ------------------------------------------------------------
     signal    TransactionRec  : inout StreamRecType ;
     variable  ErrorCount      : out   natural
   ) ;

.. _MIT/Stream/BurstFIFOsAndBurstModeControls:

Burst FIFOs and Burst Mode Controls
***********************************

The burst FIFOs hold bursts of data that is to be sent to or received from the interface. The burst FIFO can be
configured in the modes defined for :vhdlcode:`StreamFifoBurstModeType`. Currently these modes defined as a subtype of
integer, shown below. The intention is to facilitate model specific extensions without the need to define separate
transactions.

.. code-block:: VHDL

   subtype StreamFifoBurstModeType is integer ;

   -- Word mode indicates the burst FIFO contains interface words.
   -- The size of the word may either be interface specific (such as
   -- a UART which supports up to 8 bits) or be interface instance specific
   -- (such as AxiStream which supports interfaces sizes of 1, 2, 4, 8,
   -- 16, ... bytes)
   constant STREAM_BURST_WORD_MODE       : StreamFifoBurstModeType := 0 ;

   -- Word + Param mode indicates the burst FIFO contains interface
   -- words plus a parameter.   The size of the parameter is also either
   -- interface specific (such as the OSVVM UART, which uses 3 bits -
   -- one bit for each of parity, stop, and break error injection) or
   -- interface instance specific (such as AxiStream which uses the Param
   -- field to hold TUser).  AxiStream TUser may be different size for
   -- different applications.
   constant STREAM_BURST_WORD_PARAM_MODE : StreamFifoBurstModeType  := 1 ;

   -- Byte mode indicates that the burst FIFO contains bytes.
   -- The verification component assembles interface words from the bytes.
   -- This allows transfers to be conceptualized in an interface independent
   -- manner.
   constant STREAM_BURST_BYTE_MODE       : StreamFifoBurstModeType := 2 ;

:vhdlcode:`SetBurstMode` and :vhdlcode:`GetBurstMode` are directive transactions that configure the burst mode into one
of the modes defined in for :vhdlcode:`StreamFfifoBurstModeType`.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure SetBurstMode (
   ------------------------------------------------------------
     signal   TransRec    : InOut StreamRecType ;
     constant OptVal      : In    StreamFifoBurstModeType
   ) ;

   ------------------------------------------------------------
   procedure GetBurstMode (
   ------------------------------------------------------------
     signal   TransRec    : InOut StreamRecType ;
     variable OptVal      : Out   StreamFifoBurstModeType
   ) ;

.. _MIT/Stream/SetAndGetModelOptions:

Set and Get Model Options
*************************

Model operations are directive transactions that are used to configure the verification component. They can either be
used directly or with a model specific wrapper around them - see the AxiStream User Guide for examples.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure SetModelOptions (
   ------------------------------------------------------------
     signal   TransactionRec  : InOut StreamRecType ;
     constant Option          : In    integer ;
     constant OptVal          : In    boolean
   ) ;

   ------------------------------------------------------------
   procedure SetModelOptions (
   ------------------------------------------------------------
     signal   TransactionRec  : InOut StreamRecType ;
     constant Option          : In    integer ;
     constant OptVal          : In    integer
   ) ;

   ------------------------------------------------------------
   procedure SetModelOptions (
   ------------------------------------------------------------
     signal   TransactionRec  : InOut StreamRecType ;
     constant Option          : In    integer ;
     constant OptVal          : In    std_logic_vector
   ) ;

   ------------------------------------------------------------
   procedure SetModelOptions (
   ------------------------------------------------------------
     signal   TransactionRec  : InOut StreamRecType ;
     constant Option          : In    integer ;
     constant OptVal          : In    time
   ) ;

   ------------------------------------------------------------
   procedure SetModelOptions (
   ------------------------------------------------------------
     signal   TransactionRec  : InOut StreamRecType ;
     constant Option          : In    integer
   ) ;

   ------------------------------------------------------------
   procedure GetModelOptions (
   ------------------------------------------------------------
     signal   TransactionRec  : InOut StreamRecType ;
     constant Option          : In    integer ;
     variable OptVal          : Out   boolean
   ) ;

   ------------------------------------------------------------
   procedure GetModelOptions (
   ------------------------------------------------------------
     signal   TransactionRec  : InOut StreamRecType ;
     constant Option          : In    integer ;
     variable OptVal          : Out   integer
   ) ;

   ------------------------------------------------------------
   procedure GetModelOptions (
   ------------------------------------------------------------
     signal   TransactionRec  : InOut StreamRecType ;
     constant Option          : In    integer ;
     variable OptVal          : Out   std_logic_vector
   ) ;

   ------------------------------------------------------------
   procedure GetModelOptions (
   ------------------------------------------------------------
     signal   TransactionRec  : InOut StreamRecType ;
     constant Option          : In    integer ;
     variable OptVal          : Out   time
   ) ;

   ------------------------------------------------------------
   procedure GetModelOptions (
   ------------------------------------------------------------
     signal   TransactionRec  : InOut StreamRecType ;
     constant Option          : In    integer
   ) ;

.. _MIT/Stream/VerificationComponentsAndStreamModelIndependentTransactions:

Verification Components and Stream Model Independent Transactions
*****************************************************************

.. _MIT/Stream/StreamOperationType:

StreamOperationType
===================

:vhdlcode:`StreamOperationType` is an enumerated type that indicates to the verification component type of transaction
that is being dispatched. Being an enumerated type, it allows the determination of the operation in the simulator’s
waveform window. Table 4 shows the correlation between :vhdlcode:`StreamOperationType` values and the transaction name.

.. list-table:: Figure 4. Correlation between StreamOperationType and the transaction name
   :header-rows: 1
   :name: MIT/Stream/Figure4
   :widths: 276 221 221

   * - :vhdlcode:`AddressBusOperationType` Value
     - Transmitter Transaction Name Receiver Transaction Name
     -
   * - :vhdlcode:`WAIT_FOR_CLOCK`
     - :vhdlcode:`WaitForClock`
     - :vhdlcode:`WaitForClock`
   * - :vhdlcode:`WAIT_FOR_TRANSACTION`
     - :vhdlcode:`WaitForTransaction`
     - :vhdlcode:`WaitForTransaction`
   * - :vhdlcode:`GET_TRANSACTION_COUNT`
     - :vhdlcode:`GetTransactionCount`
     - :vhdlcode:`GetTransactionCount`
   * - :vhdlcode:`GET_ALERTLOG_ID`
     - :vhdlcode:`GetAlertLogID`
     - :vhdlcode:`GetAlertLogID`
   * - :vhdlcode:`SET_BURST_MODE`
     - :vhdlcode:`SetBurstMode`
     - :vhdlcode:`SetBurstMode`
   * - :vhdlcode:`GET_BURST_MODE`
     - :vhdlcode:`GetBurstMode`
     - :vhdlcode:`GetBurstMode`
   * - :vhdlcode:`SET_MODEL_OPTIONS`
     - :vhdlcode:`SetModelOptions`
     - :vhdlcode:`SetModelOptions`
   * - :vhdlcode:`GET_MODEL_OPTIONS`
     - :vhdlcode:`GetModelOptions`
     - :vhdlcode:`GetModelOptions`
   * - :vhdlcode:`SEND`
     - :vhdlcode:`Send`
     -
   * - :vhdlcode:`SEND_ASYNC`
     - :vhdlcode:`SendAsync`
     -
   * - :vhdlcode:`SEND_BURST`
     - :vhdlcode:`SendBurst`
     -
   * - :vhdlcode:`SEND_BURST_ASYNC`
     - :vhdlcode:`SendBurstAsync`
     -
   * - :vhdlcode:`GET`
     -
     - :vhdlcode:`Get`
   * - :vhdlcode:`TRY_GET`
     -
     - :vhdlcode:`TryGet`
   * - :vhdlcode:`GET_BURST`
     -
     - :vhdlcode:`GetBurst`
   * - :vhdlcode:`TRY_GET_BURST`
     -
     - :vhdlcode:`TryGetBurst`
   * - :vhdlcode:`CHECK`
     -
     - :vhdlcode:`Check`
   * - :vhdlcode:`TRY_CHECK`
     -
     - :vhdlcode:`TryCheck`
   * - :vhdlcode:`CHECK_BURST`
     -
     - :vhdlcode:`CheckBurst`
   * - :vhdlcode:`TRY_CHECK_BURST`
     -
     - :vhdlcode:`TryCheckBurst`

These values are used in the transaction dispatcher of the verification component to determine which transaction was
called and to appropriately handle the information in the record.

.. _MIT/Stream/VerificationComponentSupportFunctions:

Verification Component Support Functions
========================================

Verification component support functions help decode the operation value (:vhdlcode:`StreamOperationType`) to determine
properties about the operation. It is recommended that a verification component use these when they apply.

.. code-block:: VHDL

   ------------------------------------------------------------
   function IsTry (
   -- True when this transaction is an asynchronous or try transaction.
   -----------------------------------------------------------
     constant Operation     : in StreamOperationType
   ) return boolean ;

   ------------------------------------------------------------
   function IsCheck (
   -- True when this transaction is a check transaction.
   -----------------------------------------------------------
     constant Operation     : in StreamOperationType
   ) return boolean ;

.. _MIT/Stream/UsingTheBurstFIFOsInTheVC:

Using the Burst FIFOs in the VC
===============================

.. _MIT/Stream/InitializingBurstFIFOs:

Initializing Burst FIFOs
------------------------

The burst FIFOs need to be initialized. A good place to do this is in the transaction dispatcher of the verification
components. :ref:`Figure 5 <MIT/Stream/Figure5>` shows the declaration of a :vhdlcode:`BurstFifo`. The
:vhdlcode:`BurstFifo` is accessed as a record element of :vhdlcode:`TransRec`.

.. code-block:: VHDL
   :caption: Figure 5. BurstFifo Initialization
   :name: MIT/Stream/Figure5

   TransactionDispatcher : process
    . . .
   begin
     wait for 0 ns ;
     TransRec.BurstFifo <= NewID("RxBurstFifo", ModelID) ;
     wait for 0 ns ;

.. _MIT/Stream/AccessingBurstFIFOs:

Accessing Burst FIFOs
---------------------

The Burst Fifos support basic FIFO operations. These are shown in :ref:`Figure 6 <MIT/Stream/Figure6>`.

.. code-block:: VHDL
   :caption: Figure 6. Making the BurstFifos visible in the test sequencer (TestCtrl)
   :name: MIT/Stream/Figure6

   Push(TransRec.BurstFifo, Data) ;
   Check(TransRec.BurstFifo, Data) ;
   Data := Pop(TransRec.BurstFifo) ;

.. _MIT/Stream/PackingAndUnpackingTheFIFO:

Packing and Unpacking the FIFO
------------------------------

The burst FIFOs can be configured to be either byte width or word width (matching the interface size). The following
procedures (from :file:`FifoFillPkg_slv.vhd`) are used to transform byte width data in the burst FIFO to/from the
verification component interface width.

.. code-block:: VHDL

   ------------------------------------------------------------
   procedure PopWord (
   -- Pop a word to the VC from a byte in the BurstFifo
   -- Used to assemble bytes in the FIFO to form words in the VC
   ------------------------------------------------------------
     constant Fifo              : in    ScoreboardIDType ;
     variable Valid             : out   boolean ;
     variable Data              : out   std_logic_vector ;
     variable BytesToSend       : inout integer ;
     constant ByteAddress       : in    natural := 0
   ) ;
   ------------------------------------------------------------
   procedure PushWord (
   -- Push a word from the VC to a byte in the BurstFifo
   ------------------------------------------------------------
     constant Fifo              : in    ScoreboardIDType ;
     variable Data              : in    std_logic_vector ;
     constant DropUndriven      : in    boolean := FALSE ;
     constant ByteAddress       : in    natural := 0
   ) ;
   ------------------------------------------------------------
   procedure CheckWord (
   -- Compare a word in the VC to bytes in the BurstFifo
   ------------------------------------------------------------
     constant Fifo              : in    ScoreboardIDType ;
     variable Data              : in    std_logic_vector ;
     constant DropUndriven      : in    boolean := FALSE ;
     constant ByteAddress       : in    natural := 0
   ) ;
