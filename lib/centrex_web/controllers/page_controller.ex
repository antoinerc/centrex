defmodule CentrexWeb.PageController do
  use CentrexWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
