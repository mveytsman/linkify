defmodule Linkify.Builder do
  @moduledoc """
  Module for building the auto generated link.
  """

  @doc """
  Create a link.
  """
  def create_link(text, opts) do
    url = add_scheme(text)

    []
    |> build_attrs(url, opts, :rel)
    |> build_attrs(url, opts, :target)
    |> build_attrs(url, opts, :class)
    |> build_attrs(url, opts, :href)
    |> format_url(text, opts)
  end

  defp build_attrs(attrs, uri, %{rel: get_rel}, :rel) when is_function(get_rel, 1) do
    case get_rel.(uri) do
      nil -> attrs
      rel -> [{:rel, rel} | attrs]
    end
  end

  defp build_attrs(attrs, _, opts, :rel) do
    case Map.get(opts, :rel) do
      rel when is_binary(rel) -> [{:rel, rel} | attrs]
      _ -> attrs
    end
  end

  defp build_attrs(attrs, _, opts, :target) do
    if Map.get(opts, :new_window), do: [{:target, :_blank} | attrs], else: attrs
  end

  defp build_attrs(attrs, _, opts, :class) do
    case Map.get(opts, :class) do
      cls when is_binary(cls) -> [{:class, cls} | attrs]
      _ -> attrs
    end
  end

  defp build_attrs(attrs, url, opts, :href) do
    case Map.get(opts, :href_handler) do
      handler when is_function(handler) -> [{:href, handler.(url)} | attrs]
      _ -> [{:href, url} | attrs]
    end
  end

  defp add_scheme("http://" <> _ = url), do: url
  defp add_scheme("https://" <> _ = url), do: url
  defp add_scheme(url), do: "http://" <> url

  defp format_url(attrs, url, opts) do
    url =
      url
      |> strip_prefix(Map.get(opts, :strip_prefix, false))
      |> truncate(Map.get(opts, :truncate, false))

    attrs
    |> format_attrs()
    |> format_tag(url, opts)
  end

  defp format_attrs(attrs) do
    attrs
    |> Enum.map(fn {key, value} -> ~s(#{key}="#{value}") end)
    |> Enum.join(" ")
  end

  defp truncate(url, false), do: url
  defp truncate(url, len) when len < 3, do: url

  defp truncate(url, len) do
    if String.length(url) > len, do: String.slice(url, 0, len - 2) <> "...", else: url
  end

  defp strip_prefix(url, true) do
    url
    |> String.replace(~r/^https?:\/\//, "")
    |> String.replace(~r/^www\./, "")
  end

  defp strip_prefix(url, _), do: url

  def create_mention_link("@" <> name, _buffer, opts) do
    mention_prefix = opts[:mention_prefix]

    url = mention_prefix <> name

    []
    |> build_attrs(url, opts, :rel)
    |> build_attrs(url, opts, :target)
    |> build_attrs(url, opts, :class)
    |> build_attrs(url, opts, :href)
    |> format_mention(name, opts)
  end

  def create_hashtag_link("#" <> tag, _buffer, opts) do
    hashtag_prefix = opts[:hashtag_prefix]

    url = hashtag_prefix <> tag

    []
    |> build_attrs(url, opts, :rel)
    |> build_attrs(url, opts, :target)
    |> build_attrs(url, opts, :class)
    |> build_attrs(url, opts, :href)
    |> format_hashtag(tag, opts)
  end

  def create_email_link(email, opts) do
    []
    |> build_attrs(email, opts, :class)
    |> build_attrs("mailto:#{email}", opts, :href)
    |> format_email(email, opts)
  end

  def create_extra_link(uri, opts) do
    []
    |> build_attrs(uri, opts, :class)
    |> build_attrs(uri, opts, :rel)
    |> build_attrs(uri, opts, :target)
    |> build_attrs(uri, opts, :href)
    |> format_extra(uri, opts)
  end

  def create_phone_link(phone, opts) do
    []
    |> build_attrs(phone, opts, :class)
    |> build_attrs("tel:#{phone}", opts, :href)
    |> format_phone(phone, opts)
  end
  def format_mention(attrs, name, opts) do
    attrs
    |> format_attrs()
    |> format_tag("@#{name}", opts)
  end

  def format_hashtag(attrs, tag, opts) do
    attrs
    |> format_attrs()
    |> format_tag("##{tag}", opts)
  end

  def format_email(attrs, email, opts) do
    attrs
    |> format_attrs()
    |> format_tag(email, opts)
  end

  def format_extra(attrs, uri, opts) do
    attrs
    |> format_attrs()
    |> format_tag(uri, opts)
  end

  def format_phone(attrs, phone, opts) do
    attrs
    |> format_attrs()
    |> format_tag(phone, opts)
  end

  def format_tag(attrs, content, %{iodata: true}) do
    ["<a ", attrs, ">", content, "</a>"]
  end

  def format_tag(attrs, content, %{iodata: :safe}) do
    [{:safe, ["<a ", attrs, ">"]}, content, {:safe, "</a>"}]
  end

  def format_tag(attrs, content, _opts) do
    "<a #{attrs}>#{content}</a>"
  end
end
