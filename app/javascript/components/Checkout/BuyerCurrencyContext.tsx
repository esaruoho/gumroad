// Buyer currency context — provides the detected buyer currency and conversion utilities
// throughout the checkout flow for local price display.

import * as React from "react";

import { CurrencyCode, formatPriceCentsWithCurrencySymbol, getIsSingleUnitCurrency } from "$app/utils/currency";

export type BuyerLocalPrice = {
  currency_code: CurrencyCode;
  price_cents: number;
  suggested_price_cents: number | null;
} | null;

type BuyerCurrencyContextType = {
  /** The buyer's detected local currency, or null if same as seller's */
  buyerCurrency: CurrencyCode | null;
  /** Format an amount (in buyer's currency cents) with the buyer's currency symbol */
  formatBuyerPrice: (amountCents: number) => string;
};

const BuyerCurrencyContext = React.createContext<BuyerCurrencyContextType>({
  buyerCurrency: null,
  formatBuyerPrice: () => "",
});

export const BuyerCurrencyProvider: React.FC<{
  buyerCurrency: CurrencyCode | null;
  children: React.ReactNode;
}> = ({ buyerCurrency, children }) => {
  const formatBuyerPrice = React.useCallback(
    (amountCents: number) => {
      if (!buyerCurrency) return "";
      return formatPriceCentsWithCurrencySymbol(buyerCurrency, Math.floor(amountCents), {
        symbolFormat: "long",
        noCentsIfWhole: !getIsSingleUnitCurrency(buyerCurrency),
      });
    },
    [buyerCurrency],
  );

  return (
    <BuyerCurrencyContext.Provider value={{ buyerCurrency, formatBuyerPrice }}>
      {children}
    </BuyerCurrencyContext.Provider>
  );
};

export const useBuyerCurrency = () => React.useContext(BuyerCurrencyContext);
