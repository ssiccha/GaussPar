gap> START_TEST("parallel/special_matrices.tst");
gap> ReadPackage("GaussPar", "tst/testdata/matrices.g");;
gap> ReadPackage("GaussPar", "tst/testfunctions.g");;
gap> for i in [1..11] do result := GAUSS_TestEchelonMatTransformationBlockwiseWithGivenEchelonForm(M[i], M_height[i], M_width[i], randomSource, M_q[i], M_numberBlocks_height[i], M_numberBlocks_width[i], true); if not result then Print("Error: Special matrix number ", i); fi; od;
gap> # No matrix
gap> result := DoEchelonMatTransformationBlockwise(3, rec( galoisField := GF(2), numberBlocksHeight := 2, numberBlocksWidth := 2));
Error, no method found! For debugging hints type ?Recovery from NoMethodFound
Error, no 1st choice method found for `NumberRows' on 1 arguments
gap> STOP_TEST("parallel/special_matrices.tst");
