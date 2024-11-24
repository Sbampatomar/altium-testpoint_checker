////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// Title: TestPoint_MinDist_Check                                             //
// Author: Mario Sbampato                                                     //
// Last Edit: 30/07/2024                                                      //
// Description:                                                               //
//    Check if there are testpoints too close. User defined minimal distance  //
//  User defined Component Comment field (component comment used to define    //
//  which components are considered test points)                              //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
USES
  SysUtils, Classes, PCB_Types, PCB_Iterator, PCB_Primitives, PCB_Functions,
  PCB_Board, Dialogs, PCB;

//*****************************************************************************************************************************
FUNCTION DistanceBetweenComponents(Component1, Component2: IPCB_Component): Double;
VAR
  X1, Y1, X2, Y2: Double;
BEGIN
  X1 := Component1.X * 0.0001; // Convert from 1/10,000 mm to mm
  Y1 := Component1.Y * 0.0001; // Convert from 1/10,000 mm to mm
  X2 := Component2.X * 0.0001; // Convert from 1/10,000 mm to mm
  Y2 := Component2.Y * 0.0001; // Convert from 1/10,000 mm to mm
  Result := Sqrt(Sqr(X2 - X1) + Sqr(Y2 - Y1));
END;

//*****************************************************************************************************************************
procedure HighlightComponent(Component: IPCB_Component);
BEGIN
  //Component.Color := clRed;
END;

//*****************************************************************************************************************************
procedure ShowCloseComponentMessages(CloseComponents: TStringList);
VAR
  I: Integer;
BEGIN
  for I := 0 to CloseComponents.Count - 1 do
    ShowMessage(CloseComponents[I]);
END;

//*****************************************************************************************************************************
FUNCTION GetUserInput(Prompt: String): String;
BEGIN
  Result := InputBox('User Input', Prompt, '');
END;




//*****************************************************************************************************************************
VAR
  PCBDoc: IPCB_Board;
  Iterator, InnerIterator: IPCB_BoardIterator;
  Component, OtherComponent: IPCB_Component;
  DistanceThreshold, Distance: Double;
  CommentParameter: String;
  DistanceStr: String;
  CloseComponents: TStringList;
  WSM     : IWorkspace;
  MM      : IMessagesManager;
  FileName: String;
BEGIN
  // Get the user-defined distance threshold and comment parameter
  DistanceStr := GetUserInput('Enter the distance threshold in millimeters:');
  DistanceThreshold := StrToFloatDef(DistanceStr, 2.54); // Default to 2.54 mm if input is invalid;

  CommentParameter := GetUserInput('Enter the comment parameter to filter components:');

  // Open the PCB document
  PCBDoc := PCBServer.GetCurrentPCBBoard;
  IF (PCBDoc = nil) THEN
   BEGIN
    ShowMessage('No PCB document is currently open.');
    Exit;
   END;

  // Initialize the list to hold close components report
  CloseComponents := TStringList.Create;

  CloseComponents.Add(Format('Starting with the parameter = %s and distance = %.2f mm', [CommentParameter, DistanceThreshold]));

  TRY
    // Create an iterator for components
    Iterator := PCBDoc.BoardIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eComponentObject));
    Component := Iterator.FirstPCBObject;
    ShowMessage(Format('Starting with the parameter = %s and distance = %.2f mm', [CommentParameter, DistanceThreshold]));

    // Iterate through each component
    WHILE (Component <> nil) DO
     BEGIN
      // Check if the component's comment matches the user-defined parameter
      IF (Component.Comment.Text = CommentParameter) THEN
       BEGIN
        // Create another iterator to compare with other components
        InnerIterator := PCBDoc.BoardIterator_Create;
        InnerIterator.AddFilter_ObjectSet(MkSet(eComponentObject));
        OtherComponent := InnerIterator.FirstPCBObject;

        // Iterate through other components
        WHILE (OtherComponent <> nil) DO
         BEGIN

          // Skip if it's the same component
          IF ((OtherComponent.Comment.Text = CommentParameter) AND (OtherComponent <> Component)) THEN
           BEGIN

            // Calculate the distance between components
            Distance := DistanceBetweenComponents(Component, OtherComponent);
            Distance := RoundTo((Distance * 0.0254), -2);

            IF (Distance < DistanceThreshold) THEN
             BEGIN

              // Highlight the component and add to the messages
              //HighlightComponent(Component);
              CloseComponents.Add(Format('Component %s is close to %s (Distance: %.2f mm)',
                [Component.Name.Text, OtherComponent.Name.Text, Distance]));
             END;

           END;

          OtherComponent := InnerIterator.NextPCBObject;
         END;

        PCBDoc.BoardIterator_Destroy(InnerIterator);
       END;

      Component := Iterator.NextPCBObject;
     END;

  FINALLY
        // Specify the output file name
        FileName := 'C:\Users\mario.sbampato\Documents\altiumscript\TestPoints.txt'; // Change the path as needed

        // Save the TStringList to the file
        CloseComponents.SaveToFile(FileName);

        // Notify the user
        ShowMessage('File saved successfully to: ' + FileName);

    CloseComponents.Free;
    PCBDoc.BoardIterator_Destroy(Iterator);
  END;
END.

