.. _UG/CodeCoverage:

Code Coverage
#############

Code coverage tells which parts of a design were exercised by the tests. OSVVM collects it per test case, merges it
per test suite and per build, and links an HTML coverage report from the build report (see :ref:`RPT`).

Code coverage is supported for the Aldec simulators (Active-HDL, Riviera-PRO, VSimSA) and the Siemens simulators
(ModelSim, QuestaSim, Visualizer).

.. _UG/CodeCoverage/Enable:

Turning on Code Coverage
************************

.. grid:: 2

   .. grid-item::
      :columns: 6

      Coverage is enabled separately for analysis and simulation:

      * :ref:`RUFF/osvvm/SetCoverageAnalyzeEnable` instruments the files analyzed while it's ``true``. Turn it off
        before analyzing the testbench, so the testbench isn't part of the coverage.
      * :ref:`RUFF/osvvm/SetCoverageSimulateEnable` collects coverage in the simulations started while it's ``true``.

      Both are ``false`` by default, so simulations run fast. :ref:`RUFF/osvvm/SetCoverageEnable` (default ``true``)
      switches both off at once without changing them.

   .. grid-item::
      :columns: 6

      .. code-block:: tcl

         # File: Dut.pro
         SetCoverageAnalyzeEnable true
         analyze   Dut.vhd
         SetCoverageAnalyzeEnable false

         SetCoverageSimulateEnable true
         analyze   TbDut.vhd
         simulate  TbDut
         SetCoverageSimulateEnable false

.. _UG/CodeCoverage/Options:

Coverage Options
****************

.. grid:: 2

   .. grid-item::
      :columns: 6

      By default, OSVVM collects statement, branch and state machine coverage. The options passed to the simulator
      come from its vendor script; :ref:`RUFF/osvvm/SetCoverageAnalyzeOptions` and
      :ref:`RUFF/osvvm/SetCoverageSimulateOptions` replace them. :ref:`RUFF/osvvm/GetCoverageAnalyzeOptions` and
      :ref:`RUFF/osvvm/GetCoverageSimulateOptions` return the current ones.

   .. grid-item::
      :columns: 6

      .. tab-set::

         .. tab-item:: Riviera-PRO
            :sync: RivieraPRO

            .. code-block:: tcl

               # Defaults
               SetCoverageAnalyzeOptions  "-coverage sbm"
               SetCoverageSimulateOptions "-acdb_cov sbm -cc_all"

         .. tab-item:: Active-HDL
            :sync: ActiveHDL

            .. code-block:: tcl

               # Defaults
               SetCoverageAnalyzeOptions  "-coverage sbm"
               SetCoverageSimulateOptions "-acdb -acdb_cov sbm -cc_all"

         .. tab-item:: QuestaSim
            :sync: QuestaSim

            .. code-block:: tcl

               # Defaults
               SetCoverageAnalyzeOptions  "+cover=sbf"
               SetCoverageSimulateOptions "-coverage"

.. _UG/CodeCoverage/Merge:

Merging and Reports
*******************

.. grid:: 2

   .. grid-item::
      :columns: 6

      With coverage on, each test case writes its coverage database. When a test suite completes, the databases of
      its test cases are merged; when the build completes, the databases of all test suites are merged and an HTML
      coverage report is created.

      All of it is in :file:`<BuildName>/CodeCoverage/` of the simulation directory.

   .. grid-item::
      :columns: 6

      .. code-block:: text

         <BuildName>/
           CodeCoverage/                 (QuestaSim)
             <TestSuite>/
               <TestCaseFileName>.ucdb   <- per test case
             <BuildName>/
               <TestSuite>.ucdb          <- merged per test suite
             <BuildName>.ucdb            <- merged for the build
             <BuildName>_code_cov/       <- HTML report
