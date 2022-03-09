--
--  Copyright (C) 2022 Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
with Server;
with App;

procedure Hello is
   S : Server.Socket_Server;
begin
   S.On_Connect := App.On_Connect'Access;
   S.On_Readable := App.On_Readable'Access;
   S.On_Writable := App.On_Writable'Access;
   Server.Bind (S, "", "8000");
   loop
      Server.Poll (S);
   end loop;
exception
   when others =>
      Server.Destroy (S);
end Hello;
