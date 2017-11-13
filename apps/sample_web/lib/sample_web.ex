defmodule SampleWeb do
  @moduledoc false

  def controller do
    quote do
      use Phoenix.Controller, namespace: SampleWeb
      import Plug.Conn
      import SampleWeb.Router.Helpers
      import SampleWeb.Gettext
    end
  end


  def view do
    quote do
      use Phoenix.View, root: "lib/sample_web/templates",
                        namespace: SampleWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import SampleWeb.Router.Helpers
      import SampleWeb.ErrorHelpers
      import SampleWeb.Gettext
    end
  end


  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end


  def channel do
    quote do
      use Phoenix.Channel
      import SampleWeb.Gettext
    end
  end


  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

end
