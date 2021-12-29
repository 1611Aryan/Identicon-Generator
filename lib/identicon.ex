defmodule Identicon do
  @moduledoc """
  Documentation for `Identicon`.
  """
  def main(name) do
    name
    |> hash_input
    |> generate_color
    |> build_Grid
    |> filter_grid
    |> build_pixelmap
    |> draw_image
    |> save_to_disk(name)
  end

  def hash_input(input) do
    hex =
      :crypto.hash(:md5, input)
      |> :binary.bin_to_list()

    %Identicon.Image{hex: hex}
  end

  def generate_color(%Identicon.Image{hex: [r, g, b | _rest]} = image) do
    %Identicon.Image{image | color: {r, g, b}}
  end

  def build_Grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex
      |> Enum.chunk_every(3, 3, :discard)
      |> Enum.map(&mirror_row/1)
      |> List.flatten()
      |> Enum.with_index()

    %Identicon.Image{image | grid: grid}
  end

  def mirror_row(row) do
    [a, b | _rest] = row

    row ++ [b, a]
  end

  def filter_grid(%Identicon.Image{grid: grid} = image) do
    grid =
      Enum.filter(grid, fn {value, _index} ->
        rem(value, 2) == 0
      end)

    %Identicon.Image{image | grid: grid}
  end

  def build_pixelmap(%Identicon.Image{grid: grid} = image) do
    pixelmap =
      Enum.map(
        grid,
        fn {_value, index} ->
          x = rem(index, 5) * 50
          y = div(index, 5) * 50
          top_left = {x, y}
          bottom_right = {x + 50, y + 50}

          {top_left, bottom_right}
        end
      )

    %Identicon.Image{image | pixelmap: pixelmap}
  end

  def draw_image(%Identicon.Image{color: color, pixelmap: pixelmap}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each(pixelmap, fn {top_left, bottom_right} ->
      :egd.filledRectangle(image, top_left, bottom_right, fill)
    end)

    :egd.render(image)
  end

  def save_to_disk(image, filename) do
    File.mkdir_p!(Path.absname("images"))
    File.write!(Path.absname("images/#{filename}.png"), image)
  end
end
