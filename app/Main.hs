{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE NumericUnderscores #-}

module Main (main) where

import Data.Text (Text)
import Ledger (
  CardanoTx,
  PaymentPubKeyHash,
  getCardanoTxId
 )
import Ledger.Constraints qualified as Constraints
import Ledger.Ada qualified as Ada
import Plutus.Contract qualified as Contract
import Plutus.Contract (Contract, submitTx)
import Plutus.PAB.Effects.Contract.Builtin (EmptySchema)
import Test.Plutip.Contract (
  assertExecution,
  initAda,
  withContract,
  initAndAssertAda
 )
import Test.Plutip.LocalCluster (withCluster)
import Test.Plutip.Predicate (shouldSucceed)
import Test.Tasty (TestTree, defaultMain)


main :: IO ()
main = defaultMain test

test :: TestTree
test =
  withCluster
    "Basic Contract"
      [
        -- Basic Succeed test
        assertExecution
          "Pay from wallet to wallet"
          (initAda [100] <> initAndAssertAda [100, 13] 123)
          (withContract $ \[pkh1] -> payTo pkh1 10_000_000)
          [shouldSucceed]
      ]

payTo :: PaymentPubKeyHash -> Integer -> Contract () EmptySchema Text CardanoTx
payTo toPkh amt = do
  tx <- submitTx (Constraints.mustPayToPubKey toPkh (Ada.lovelaceValueOf amt))
  _ <- Contract.awaitTxConfirmed (getCardanoTxId tx)
  pure tx
