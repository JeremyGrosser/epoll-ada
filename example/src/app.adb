--
--  Copyright (C) 2022 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with Ada.Text_IO; use Ada.Text_IO;

package body App is
   use GNAT.Sockets;
   use Ada.Streams;

   function To_String
      (SEA : Stream_Element_Array)
      return String
   is
      Offset : Stream_Element_Offset := SEA'First;
      S      : String (1 .. SEA'Length);
   begin
      for I in S'Range loop
         S (I) := Character'Val (SEA (Offset));
         Offset := Offset + 1;
      end loop;
      return S;
   end To_String;

   function On_Connect
      (Socket : Socket_Type)
      return Server.Socket_Action
   is
   begin
      Put_Line ("On_Connect");
      return Server.No_Action;
   end On_Connect;

   function On_Readable
      (Socket : Socket_Type)
      return Server.Socket_Action
   is
      Buffer : Stream_Element_Array (1 .. 1024);
      Last   : Stream_Element_Offset;
   begin
      Receive_Socket (Socket, Buffer, Last);
      if Last = Buffer'First - 1 then
         Put_Line ("Client closed connection");
         return Server.Should_Close;
      else
         Put_Line ("Received: " & To_String (Buffer (1 .. Last)));
         return Server.No_Action;
      end if;
   end On_Readable;

   function On_Writable
      (Socket : Socket_Type)
      return Server.Socket_Action
   is
      Channel : constant GNAT.Sockets.Stream_Access := Stream (Socket);
   begin
      String'Write (Channel, "hello world" & ASCII.CR & ASCII.LF);
      return Server.Should_Close;
   end On_Writable;
end App;
