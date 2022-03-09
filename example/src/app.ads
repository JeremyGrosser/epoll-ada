--
--  Copyright (C) 2022 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with Ada.Streams;
with GNAT.Sockets;
with Server;

package App is
   function On_Connect
      (Socket : GNAT.Sockets.Socket_Type)
      return Server.Socket_Action;

   function On_Readable
      (Socket : GNAT.Sockets.Socket_Type)
      return Server.Socket_Action;

   function On_Writable
      (Socket : GNAT.Sockets.Socket_Type)
      return Server.Socket_Action;

private

   function To_String
      (SEA : Ada.Streams.Stream_Element_Array)
      return String;

end App;
