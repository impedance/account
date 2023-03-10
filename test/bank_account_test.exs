defmodule BankAccount do
  def start do
    await([])
  end

  def await(events) do
    receive do
      {:check_balance, pid} -> divulge_balance(pid, events)
      {:deposit, amount} -> deposit(amount, events)
      {:withdraw, amount} -> withdraw(amount, events)
    end

    await(events)
  end

  defp deposit(amount, events) do
    await(events ++ [{:deposit, amount}])
  end

  defp withdraw(amount, events) do
    await(events ++ [{:withdrawal, amount}])
  end

  def divulge_balance(pid, events) do
    send(pid, {:balance, calculate_balance(events)})
  end

  defp calculate_balance(events) do
    deposits = sum(just_deposits(events))
    withdrawals = sum(just_withdrawals(events))
    deposits - withdrawals
  end

  defp sum(events) do
    Enum.reduce(events, 0, fn {_, amount}, acc -> acc + amount end)
  end

  defp just_type(events, expected_type) do
    Enum.filter(events, fn {type, _} -> type == expected_type end)
  end
  
  defp just_deposits(events) do
	just_type(events, :deposit)
  end

  defp just_withdrawals(events) do
	just_type(events, :withdrawal)
  end

  #   defp divide(events) do
  #     Enum.reduce(events, 0, fn {_, amount}, acc -> acc - amount end)
  #   end
end

defmodule BankAccountTest do
  use ExUnit.Case

  test "starts with balance 0" do
    account = spawn_link(BankAccount, :start, [])
    verify_balance_is(0, account)
  end

  test "has balance incremet" do
    account = spawn_link(BankAccount, :start, [])
    send(account, {:deposit, 10})
    verify_balance_is(10, account)
  end

  test "has balance decrement" do
    account = spawn_link(BankAccount, :start, [])
    send(account, {:deposit, 20})
    send(account, {:withdraw, 10})
    verify_balance_is(10, account)
  end

  def verify_balance_is(expected_balance, account) do
    send(account, {:check_balance, self()})
    assert_receive {:balance, ^expected_balance}
  end
end
